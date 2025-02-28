;; TetraLink Network Contract
;; Service discovery and connection network for microservices

;; Constants
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_VERSION (err u400))
(define-constant ERR_INVALID_STATUS (err u400))
(define-constant MAX_SERVICE_NAME_LENGTH u64)
(define-constant MAX_METADATA_LENGTH u1024)
(define-constant HEARTBEAT_TIMEOUT u144) ;; ~24 hours in blocks

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
        metadata: (optional (string-utf8 1024))
    }
)

(define-map service-names
    { name: (string-ascii 64) }
    { service-id: uint }
)

(define-map service-versions
    { service-id: uint, version: (string-ascii 32) }
    { 
        active: bool,
        deployed-at: uint,
        previous-version: (optional (string-ascii 32))
    }
)

;; Data variables
(define-data-var next-service-id uint u1)

;; Private functions
(define-private (validate-service-name (name (string-ascii 64)))
    (let
        ((length (len name)))
        (and (> length u0) (<= length MAX_SERVICE_NAME_LENGTH))
    )
)

(define-private (validate-version (version (string-ascii 32)))
    (let
        ((length (len version)))
        (and (> length u0) (<= length u32))
    )
)

(define-private (is-valid-status (status (string-ascii 16)))
    (or
        (is-eq status STATUS_ACTIVE)
        (is-eq status STATUS_INACTIVE)
        (is-eq status STATUS_MAINTENANCE)
    )
)

(define-private (check-service-owner (service-id uint))
    (let ((service (map-get? services {service-id: service-id})))
        (and
            (is-some service)
            (is-eq (get owner (unwrap-panic service)) tx-sender)
        )
    )
)

;; Public functions
;; [Previous functions remain unchanged]

(define-public (heartbeat (service-id uint))
    (let ((service (map-get? services {service-id: service-id})))
        (if (check-service-owner service-id)
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {last-heartbeat: block-height})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

(define-public (update-service-status (service-id uint) (new-status (string-ascii 16)))
    (let ((service (map-get? services {service-id: service-id})))
        (if (and
                (check-service-owner service-id)
                (is-valid-status new-status)
            )
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {status: new-status})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

(define-public (transfer-ownership (service-id uint) (new-owner principal))
    (let ((service (map-get? services {service-id: service-id})))
        (if (check-service-owner service-id)
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {owner: new-owner})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

(define-public (deactivate-service (service-id uint))
    (let ((service (map-get? services {service-id: service-id})))
        (if (check-service-owner service-id)
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) 
                        {
                            status: STATUS_INACTIVE,
                            last-heartbeat: block-height
                        }
                    )
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)
