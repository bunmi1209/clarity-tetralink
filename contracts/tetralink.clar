;; TetraLink Network Contract
;; Service discovery and connection network for microservices

;; Constants
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_VERSION (err u400))
(define-constant ERR_INVALID_STATUS (err u400))
(define-constant ERR_RATE_LIMITED (err u429))
(define-constant MAX_SERVICE_NAME_LENGTH u64)
(define-constant MAX_METADATA_LENGTH u1024)
(define-constant HEARTBEAT_TIMEOUT u144) ;; ~24 hours in blocks
(define-constant HEARTBEAT_RATE_LIMIT u6) ;; Minimum blocks between updates

;; Status constants
(define-constant STATUS_ACTIVE "active")
(define-constant STATUS_INACTIVE "inactive")
(define-constant STATUS_MAINTENANCE "maintenance")

;; Data structures
(define-map services
    { service-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        endpoint: (string-ascii 256),
        status: (string-ascii 16),
        last-heartbeat: uint,
        version: (string-ascii 32),
        metadata: (optional (string-utf8 1024)),
        health-score: uint,
        total-uptime: uint
    }
)

[Previous maps remain unchanged...]

;; New utility functions
(define-private (is-service-stale (service-id uint))
    (let (
        (service (unwrap! (map-get? services {service-id: service-id}) false))
        (time-diff (- block-height (get last-heartbeat service)))
    )
    (> time-diff HEARTBEAT_TIMEOUT)
    )
)

(define-private (validate-endpoint (endpoint (string-ascii 256)))
    (let ((length (len endpoint)))
        (and 
            (> length u0)
            (<= length u256)
            (is-some (index-of endpoint "://"))
        )
    )
)

(define-private (can-update-heartbeat (service-id uint))
    (let (
        (service (unwrap! (map-get? services {service-id: service-id}) false))
        (last-update (get last-heartbeat service))
    )
    (>= (- block-height last-update) HEARTBEAT_RATE_LIMIT)
    )
)

;; Enhanced public functions
(define-public (heartbeat (service-id uint))
    (let ((service (map-get? services {service-id: service-id})))
        (asserts! (check-service-owner service-id) ERR_UNAUTHORIZED)
        (asserts! (can-update-heartbeat service-id) ERR_RATE_LIMITED)
        (let (
            (current-service (unwrap-panic service))
            (new-health-score (+ (default-to u0 (get health-score current-service)) u1))
        )
            (map-set services
                {service-id: service-id}
                (merge current-service {
                    last-heartbeat: block-height,
                    health-score: new-health-score,
                    total-uptime: (+ (default-to u0 (get total-uptime current-service)) u1)
                })
            )
            (ok true)
        )
    )
)

;; New read-only functions
(define-read-only (get-service-health (service-id uint))
    (let ((service (map-get? services {service-id: service-id})))
        (if (is-some service)
            (ok {
                is-stale: (is-service-stale service-id),
                health-score: (get health-score (unwrap-panic service)),
                total-uptime: (get total-uptime (unwrap-panic service))
            })
            ERR_NOT_FOUND
        )
    )
)

[Previous functions remain unchanged...]
