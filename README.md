# TetraLink Network

A decentralized network for connecting and managing microservices on-chain. TetraLink enables service discovery, registration, and secure communication between different microservices in a decentralized manner.

## Features
- Service registration and deregistration
- Service discovery and lookup
- Secure service-to-service communication
- Service health monitoring
- Decentralized service registry
- Service versioning and version history tracking
- Extended service metadata support
- Semantic versioning compatibility

## Usage
Services can register themselves on the network by calling the `register-service` function with their service details, version, and optional metadata. Other services can discover and connect to registered services using the `get-service` function.

### Service Versioning
TetraLink now supports semantic versioning for services. When registering a service, specify its version:
```clarity
(register-service "my-service" "http://localhost:8080" "1.0.0" (some u"{\"description\": \"My service\"}")
```

Services can update their version using:
```clarity
(update-service-version service-id "1.1.0")
```

### Service Metadata
Services can include additional metadata during registration or update it later:
- Documentation links
- Service description
- Dependencies
- Configuration details

## Security
All service registrations are verified and can only be modified by the original registrant. Service communications are secured through the blockchain's native security features.
