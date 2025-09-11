# Subscription Service Smart Contracts

## Overview
Implementation of two Clarity smart contracts for managing subscription services and access permissions on the Stacks blockchain.

## Contracts

### subscription-contract.clar
- Create subscription plans with pricing and billing cycles
- User subscription management with auto-renew options
- Payment processing with platform fees
- Provider plan management
- Platform pause/resume controls

### access-permissions.clar  
- Protected resource creation and management
- Role-based access control system
- Permission granting with expiration dates
- Access logging and tracking
- Resource deactivation capabilities

## Features
- Subscription billing with automated payments
- Role and permission-based access control
- Platform fee collection (2.5%)
- User subscription tracking
- Resource access logging
- Admin controls for system management

## Technical Details
- All contracts use stacks-block-height for timestamping
- No cross-contract dependencies
- Comprehensive error handling
- Over 400 lines of Clarity code combined
- Passes clarinet check with warnings only

## Testing
- Contract scaffolding created
- Ready for comprehensive unit testing
- All syntax validated
