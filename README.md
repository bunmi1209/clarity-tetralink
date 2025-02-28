[Previous README content]

### Service Health Monitoring
TetraLink now includes built-in health monitoring features:
- Heartbeat mechanism to track service availability
- Service status management (active/inactive/maintenance)
- Automatic stale service detection

```clarity
;; Update service heartbeat
(heartbeat service-id)

;; Update service status
(update-service-status service-id "maintenance")
```

### Service Ownership
Services can now be transferred between owners:
```clarity
(transfer-ownership service-id new-owner-principal)
```

### Service Lifecycle Management
Services can be deactivated when needed:
```clarity
(deactivate-service service-id)
```
