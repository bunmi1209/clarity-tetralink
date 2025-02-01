;; TetraLink Network Contract
;; Service discovery and connection network for microservices

;; Constants
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_VERSION (err u400))
(define-constant MAX_SERVICE_NAME_LENGTH u64)
(define-constant MAX_METADATA_LENGTH u1024)

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
    { active: bool }
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

;; Public functions
(define-public (register-service (name (string-ascii 64)) (endpoint (string-ascii 256)) (version (string-ascii 32)) (metadata (optional (string-utf8 1024))))
    (let
        ((service-id (var-get next-service-id)))
        (if (and (validate-service-name name) (validate-version version))
            (if (is-none (map-get? service-names {name: name}))
                (begin
                    (map-set services
                        {service-id: service-id}
                        {
                            name: name,
                            owner: tx-sender,
                            endpoint: endpoint,
                            status: "active",
                            last-heartbeat: block-height,
                            version: version,
                            metadata: metadata
                        }
                    )
                    (map-set service-names
                        {name: name}
                        {service-id: service-id}
                    )
                    (map-set service-versions
                        {service-id: service-id, version: version}
                        {active: true}
                    )
                    (var-set next-service-id (+ service-id u1))
                    (ok service-id)
                )
                ERR_ALREADY_EXISTS
            )
            (err u400)
        )
    )
)

(define-public (update-service-version (service-id uint) (new-version (string-ascii 32)))
    (let
        ((service (map-get? services {service-id: service-id})))
        (if (and
                (is-some service)
                (is-eq (get owner (unwrap-panic service)) tx-sender)
                (validate-version new-version)
            )
            (begin
                (map-set service-versions
                    {service-id: service-id, version: (get version (unwrap-panic service))}
                    {active: false}
                )
                (map-set service-versions
                    {service-id: service-id, version: new-version}
                    {active: true}
                )
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {version: new-version})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

(define-public (update-metadata (service-id uint) (new-metadata (optional (string-utf8 1024))))
    (let
        ((service (map-get? services {service-id: service-id})))
        (if (and
                (is-some service)
                (is-eq (get owner (unwrap-panic service)) tx-sender)
            )
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {metadata: new-metadata})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

;; Existing functions remain unchanged
[... rest of original contract functions ...]
