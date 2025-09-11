;; subscription-contract
;; Handles recurring subscription payments and management

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_NOT_FOUND (err u501))
(define-constant ERR_INVALID_INPUT (err u502))
(define-constant ERR_SUBSCRIPTION_EXPIRED (err u503))
(define-constant ERR_INSUFFICIENT_BALANCE (err u504))
(define-constant PLATFORM_FEE_BPS u250) ;; 2.5%

;; data vars
(define-data-var next-subscription-id uint u1)
(define-data-var total-subscriptions uint u0)
(define-data-var platform-paused bool false)

;; data maps
(define-map subscriptions
  { subscription-id: uint }
  {
    subscriber: principal,
    provider: principal,
    plan-id: uint,
    amount: uint,
    billing-period: uint,
    start-block: uint,
    last-payment-block: uint,
    active: bool,
    auto-renew: bool
  }
)

(define-map subscription-plans
  { plan-id: uint }
  {
    provider: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    price: uint,
    billing-cycle: uint,
    active: bool,
    created-at: uint
  }
)

(define-map user-subscriptions
  { user: principal }
  { subscription-ids: (list 100 uint) }
)

(define-map provider-plans
  { provider: principal }
  { plan-ids: (list 50 uint) }
)

;; public functions
(define-public (create-plan (name (string-ascii 50)) (description (string-ascii 200)) (price uint) (billing-cycle uint))
  (let ((plan-id (var-get next-subscription-id)))
    (asserts! (not (var-get platform-paused)) ERR_UNAUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_INPUT)
    (asserts! (> billing-cycle u0) ERR_INVALID_INPUT)

    (map-set subscription-plans { plan-id: plan-id }
      { provider: tx-sender,
        name: name,
        description: description,
        price: price,
        billing-cycle: billing-cycle,
        active: true,
        created-at: stacks-block-height })

    (let ((existing (default-to { plan-ids: (list) } (map-get? provider-plans { provider: tx-sender }))))
      (map-set provider-plans { provider: tx-sender }
        { plan-ids: (unwrap-panic (as-max-len? (append (get plan-ids existing) plan-id) u50)) })
    )

    (var-set next-subscription-id (+ plan-id u1))
    (ok plan-id)
  )
)

(define-public (subscribe (plan-id uint) (auto-renew bool))
  (let (
      (plan (unwrap! (map-get? subscription-plans { plan-id: plan-id }) ERR_NOT_FOUND))
      (subscription-id (var-get next-subscription-id))
    )
    (asserts! (not (var-get platform-paused)) ERR_UNAUTHORIZED)
    (asserts! (get active plan) ERR_INVALID_INPUT)
    (asserts! (>= (stx-get-balance tx-sender) (get price plan)) ERR_INSUFFICIENT_BALANCE)

    ;; First payment
    (let ((fee (/ (* (get price plan) PLATFORM_FEE_BPS) u10000)))
      (try! (stx-transfer? (- (get price plan) fee) tx-sender (get provider plan)))
      (try! (stx-transfer? fee tx-sender CONTRACT_OWNER))
    )

    (map-set subscriptions { subscription-id: subscription-id }
      { subscriber: tx-sender,
        provider: (get provider plan),
        plan-id: plan-id,
        amount: (get price plan),
        billing-period: (get billing-cycle plan),
        start-block: stacks-block-height,
        last-payment-block: stacks-block-height,
        active: true,
        auto-renew: auto-renew })

    (let ((existing (default-to { subscription-ids: (list) } (map-get? user-subscriptions { user: tx-sender }))))
      (map-set user-subscriptions { user: tx-sender }
        { subscription-ids: (unwrap-panic (as-max-len? (append (get subscription-ids existing) subscription-id) u100)) })
    )

    (var-set next-subscription-id (+ subscription-id u1))
    (var-set total-subscriptions (+ (var-get total-subscriptions) u1))
    (ok subscription-id)
  )
)

(define-public (renew-subscription (subscription-id uint))
  (let ((sub (unwrap! (map-get? subscriptions { subscription-id: subscription-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get subscriber sub)) ERR_UNAUTHORIZED)
    (asserts! (get active sub) ERR_SUBSCRIPTION_EXPIRED)
    (asserts! (>= (stx-get-balance tx-sender) (get amount sub)) ERR_INSUFFICIENT_BALANCE)

    (let ((fee (/ (* (get amount sub) PLATFORM_FEE_BPS) u10000)))
      (try! (stx-transfer? (- (get amount sub) fee) tx-sender (get provider sub)))
      (try! (stx-transfer? fee tx-sender CONTRACT_OWNER))
    )

    (map-set subscriptions { subscription-id: subscription-id }
      (merge sub { last-payment-block: stacks-block-height }))
    (ok true)
  )
)

(define-public (cancel-subscription (subscription-id uint))
  (let ((sub (unwrap! (map-get? subscriptions { subscription-id: subscription-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get subscriber sub)) ERR_UNAUTHORIZED)
    (map-set subscriptions { subscription-id: subscription-id }
      (merge sub { active: false, auto-renew: false }))
    (ok true)
  )
)

(define-public (deactivate-plan (plan-id uint))
  (let ((plan (unwrap! (map-get? subscription-plans { plan-id: plan-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get provider plan)) ERR_UNAUTHORIZED)
    (map-set subscription-plans { plan-id: plan-id }
      (merge plan { active: false }))
    (ok true)
  )
)

(define-public (pause-platform)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set platform-paused true)
    (ok true)
  )
)

(define-public (resume-platform)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set platform-paused false)
    (ok true)
  )
)

;; read-only functions
(define-read-only (get-subscription (subscription-id uint))
  (map-get? subscriptions { subscription-id: subscription-id })
)

(define-read-only (get-plan (plan-id uint))
  (map-get? subscription-plans { plan-id: plan-id })
)

(define-read-only (get-user-subscriptions (user principal))
  (match (map-get? user-subscriptions { user: user })
    subs (get subscription-ids subs)
    (list)
  )
)

(define-read-only (get-provider-plans (provider principal))
  (match (map-get? provider-plans { provider: provider })
    plans (get plan-ids plans)
    (list)
  )
)

(define-read-only (is-subscription-due (subscription-id uint))
  (match (get-subscription subscription-id)
    sub (> (- stacks-block-height (get last-payment-block sub)) (get billing-period sub))
    false
  )
)

(define-read-only (get-total-subscriptions)
  (var-get total-subscriptions)
)

(define-read-only (is-platform-paused)
  (var-get platform-paused)
)
