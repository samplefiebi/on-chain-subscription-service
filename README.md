# On-Chain Subscription Service

A decentralized subscription and membership management system built on the Stacks blockchain using Clarity smart contracts.

## Overview

This project implements a comprehensive subscription-based service that enables:

- **Recurring Payment Management**: Automated subscription billing cycles
- **Member Access Control**: Granular permissions for content and services
- **Decentralized Architecture**: Trustless operation without intermediaries
- **Flexible Plans**: Multiple subscription tiers and durations

## Architecture

### Core Components

1. **Subscription Contract** (`subscription-contract.clar`)
   - Manages recurring payment schedules
   - Handles subscription lifecycle (create, renew, cancel)
   - Tracks payment history and billing cycles
   - Implements automatic renewals with grace periods

2. **Access Permissions Contract** (`access-permissions.clar`)
   - Controls member-only content access
   - Manages service-level permissions
   - Implements role-based access control
   - Handles subscription tier validations

## Features

### Subscription Management
- Create subscription plans with custom pricing and durations
- Automatic billing cycle management
- Grace period handling for failed payments
- Subscription upgrade/downgrade functionality
- Comprehensive audit trail

### Access Control
- Token-gated content and services
- Hierarchical permission levels
- Time-based access validation
- Service-specific authorization

### Security Features
- Multi-signature admin controls
- Emergency pause functionality
- Protected contract upgrades
- Transparent fee structures

## Smart Contracts

### Subscription Contract
**Purpose**: Core subscription logic and payment processing

**Key Functions**:
- `create-subscription`: Initialize new subscription plans
- `subscribe`: User enrollment in subscription plans
- `process-payment`: Handle recurring billing
- `cancel-subscription`: Terminate subscriptions
- `get-subscription-status`: Query current subscription state

**Data Structures**:
- Subscription plans with pricing and duration
- User subscription records
- Payment history tracking
- Billing cycle management

### Access Permissions Contract
**Purpose**: Content and service access management

**Key Functions**:
- `grant-access`: Assign permissions to subscribers
- `revoke-access`: Remove access rights
- `check-permission`: Validate user access
- `update-tier`: Modify subscription level access
- `get-user-permissions`: Query user access rights

**Data Structures**:
- Permission levels and hierarchies
- Service-specific access rules
- Time-bounded access tokens
- User permission mappings

## Technical Specifications

### Blockchain
- **Network**: Stacks Blockchain
- **Language**: Clarity
- **Token Standard**: SIP-010 (Fungible Tokens)
- **Consensus**: Proof of Transfer (PoX)

### Dependencies
- Clarinet development framework
- Stacks blockchain testnet/mainnet
- Web3 wallet integration
- Frontend interface (optional)

## Development Setup

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Git version control
- Code editor with Clarity support

### Installation
```bash
# Clone the repository
git clone https://github.com/samplefiebi/on-chain-subscription-service.git

# Navigate to project directory
cd on-chain-subscription-service

# Install dependencies
npm install

# Run contract tests
clarinet test

# Check contract syntax
clarinet check
```

### Testing
```bash
# Run all tests
clarinet test

# Test specific contract
clarinet test --filter subscription-contract

# Integration testing
clarinet integrate
```

## Usage Examples

### Creating a Subscription Plan
```clarity
(contract-call? .subscription-contract create-subscription
  u100000000  ;; 100 STX price
  u2592000    ;; 30 days duration
  "Premium Plan"
  "Full access to premium features"
)
```

### Subscribing to a Service
```clarity
(contract-call? .subscription-contract subscribe
  u1  ;; plan-id
  tx-sender
)
```

### Checking Access Permissions
```clarity
(contract-call? .access-permissions check-permission
  tx-sender
  "premium-content"
)
```

## Deployment

### Testnet Deployment
```bash
# Deploy to testnet
clarinet deploy --testnet

# Verify deployment
clarinet console --testnet
```

### Mainnet Deployment
```bash
# Deploy to mainnet (after thorough testing)
clarinet deploy --mainnet
```

## Security Considerations

### Audit Status
- [ ] Internal code review
- [ ] External security audit
- [ ] Bug bounty program
- [ ] Formal verification

### Risk Mitigation
- Circuit breaker patterns
- Rate limiting mechanisms
- Multi-signature admin controls
- Gradual rollout strategy

## Contributing

### Development Process
1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Submit pull request
5. Code review and merge

### Code Standards
- Follow Clarity best practices
- Comprehensive test coverage
- Clear documentation
- Security-first approach

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [Wiki](../../wiki)
- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Discord**: [Community Server](https://discord.gg/stacks)

## Roadmap

### Phase 1 (Current)
- Core subscription functionality
- Basic access control
- Testnet deployment

### Phase 2 (Q1 2025)
- Advanced analytics
- Multi-token support
- Mobile app integration

### Phase 3 (Q2 2025)
- Cross-chain compatibility
- Enterprise features
- Governance token launch

## Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language development team
- Open source contributors
- Community feedback and testing

---

*Built with ❤️ on the Stacks blockchain*
