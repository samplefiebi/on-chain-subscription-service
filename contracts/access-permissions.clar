;; access-permissions
;; Manages member-only content and service access control

;; constants
(define-constant ADMIN tx-sender)
(define-constant ERR_UNAUTHORIZED (err u600))
(define-constant ERR_NOT_FOUND (err u601))
(define-constant ERR_INVALID_INPUT (err u602))
(define-constant ERR_ACCESS_DENIED (err u603))

;; data vars
(define-data-var next-resource-id uint u1)
(define-data-var next-role-id uint u1)
(define-data-var total-resources uint u0)
(define-data-var system-paused bool false)

;; data maps
(define-map protected-resources
  { resource-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    access-level: uint,
    created-at: uint,
    active: bool
  }
)

(define-map user-permissions
  { user: principal, resource-id: uint }
  {
    access-level: uint,
    granted-at: uint,
    granted-by: principal,
    expires-at: (optional uint)
  }
)

(define-map access-roles
  { role-id: uint }
  {
    name: (string-ascii 30),
    description: (string-ascii 100),
    access-level: uint,
    created-by: principal,
    active: bool
  }
)

(define-map user-roles
  { user: principal }
  { role-ids: (list 20 uint) }
)

(define-map resource-access-log
  { user: principal, resource-id: uint }
  {
    last-accessed: uint,
    access-count: uint
  }
)

;; public functions
(define-public (create-resource (name (string-ascii 50)) (description (string-ascii 200)) (access-level uint))
  (let ((resource-id (var-get next-resource-id)))
    (asserts! (not (var-get system-paused)) ERR_UNAUTHORIZED)
    (asserts! (> access-level u0) ERR_INVALID_INPUT)

    (map-set protected-resources { resource-id: resource-id }
      { owner: tx-sender,
        name: name,
        description: description,
        access-level: access-level,
        created-at: stacks-block-height,
        active: true })

    (var-set next-resource-id (+ resource-id u1))
    (var-set total-resources (+ (var-get total-resources) u1))
    (ok resource-id)
  )
)

(define-public (create-role (name (string-ascii 30)) (description (string-ascii 100)) (access-level uint))
  (let ((role-id (var-get next-role-id)))
    (asserts! (not (var-get system-paused)) ERR_UNAUTHORIZED)

    (map-set access-roles { role-id: role-id }
      { name: name,
        description: description,
        access-level: access-level,
        created-by: tx-sender,
        active: true })

    (var-set next-role-id (+ role-id u1))
    (ok role-id)
  )
)

(define-public (grant-permission (user principal) (resource-id uint) (access-level uint) (expires-at (optional uint)))
  (let ((resource (unwrap! (map-get? protected-resources { resource-id: resource-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR_UNAUTHORIZED)
    (asserts! (get active resource) ERR_INVALID_INPUT)

    (map-set user-permissions { user: user, resource-id: resource-id }
      { access-level: access-level,
        granted-at: stacks-block-height,
        granted-by: tx-sender,
        expires-at: expires-at })
    (ok true)
  )
)

(define-public (assign-role (user principal) (role-id uint))
  (let ((role (unwrap! (map-get? access-roles { role-id: role-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get created-by role)) ERR_UNAUTHORIZED)
    (asserts! (get active role) ERR_INVALID_INPUT)

    (let ((existing (default-to { role-ids: (list) } (map-get? user-roles { user: user }))))
      (map-set user-roles { user: user }
        { role-ids: (unwrap-panic (as-max-len? (append (get role-ids existing) role-id) u20)) })
    )
    (ok true)
  )
)

(define-public (revoke-permission (user principal) (resource-id uint))
  (let ((resource (unwrap! (map-get? protected-resources { resource-id: resource-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR_UNAUTHORIZED)
    (map-delete user-permissions { user: user, resource-id: resource-id })
    (ok true)
  )
)

(define-public (access-resource (resource-id uint))
  (let ((resource (unwrap! (map-get? protected-resources { resource-id: resource-id }) ERR_NOT_FOUND)))
    (asserts! (get active resource) ERR_ACCESS_DENIED)
    (asserts! (has-access tx-sender resource-id) ERR_ACCESS_DENIED)

    ;; Log access
    (let ((log (default-to { last-accessed: u0, access-count: u0 } 
                           (map-get? resource-access-log { user: tx-sender, resource-id: resource-id }))))
      (map-set resource-access-log { user: tx-sender, resource-id: resource-id }
        { last-accessed: stacks-block-height,
          access-count: (+ (get access-count log) u1) })
    )
    (ok true)
  )
)

(define-public (deactivate-resource (resource-id uint))
  (let ((resource (unwrap! (map-get? protected-resources { resource-id: resource-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR_UNAUTHORIZED)
    (map-set protected-resources { resource-id: resource-id }
      (merge resource { active: false }))
    (ok true)
  )
)

(define-public (pause-system)
  (begin
    (asserts! (is-eq tx-sender ADMIN) ERR_UNAUTHORIZED)
    (var-set system-paused true)
    (ok true)
  )
)

(define-public (resume-system)
  (begin
    (asserts! (is-eq tx-sender ADMIN) ERR_UNAUTHORIZED)
    (var-set system-paused false)
    (ok true)
  )
)

;; read-only functions
(define-read-only (get-resource (resource-id uint))
  (map-get? protected-resources { resource-id: resource-id })
)

(define-read-only (get-role (role-id uint))
  (map-get? access-roles { role-id: role-id })
)

(define-read-only (get-user-permission (user principal) (resource-id uint))
  (map-get? user-permissions { user: user, resource-id: resource-id })
)

(define-read-only (get-user-roles (user principal))
  (match (map-get? user-roles { user: user })
    roles (get role-ids roles)
    (list)
  )
)

(define-read-only (has-access (user principal) (resource-id uint))
  (let ((resource (unwrap! (map-get? protected-resources { resource-id: resource-id }) false)))
    ;; Check direct permission
    (match (get-user-permission user resource-id)
      perm (and (>= (get access-level perm) (get access-level resource))
                (match (get expires-at perm)
                  exp-block (> exp-block stacks-block-height)
                  true))
      false)
  )
)

(define-read-only (get-access-log (user principal) (resource-id uint))
  (map-get? resource-access-log { user: user, resource-id: resource-id })
)

(define-read-only (get-total-resources)
  (var-get total-resources)
)

(define-read-only (is-system-paused)
  (var-get system-paused)
)
