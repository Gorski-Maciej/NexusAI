# 🚀 OPA Deployment Guide — NexusAI Production

> **Status:** Dokumentacja techniczna v1.0
> **Data:** 2026-07-07
> **Powiązany:** `18_OPA_API_REFERENCE.md`, `17_IMPLEMENTATION_ROADMAP.md`
> **OPA wersja:** ≥ 0.60.0

---

## 1. Wymagania systemowe

| Komponent | Minimum | Rekomendowane |
|---|---|---|
| CPU | 1 vCPU | 2 vCPU |
| RAM | 256 MB | 512 MB |
| Disk | 100 MB | 500 MB (logi) |
| Sieć | 100 Mbps | 1 Gbps |

**Wydajność OPA:** ~50 000 ewaluacji/sekundę na 1 vCPU dla średniej wielkości polityk (10-50 reguł). Każda ewaluacja to < 1 ms dla prostych reguł, do 5 ms dla złożonych warunków.

---

## 2. Uruchomienie Docker

### 2.1 Podstawowy kontener

```bash
# Uruchomienie OPA jako serwer decyzyjny
docker run -d \
    --name opa-nexusai \
    -p 8181:8181 \
    -v $(pwd)/policies/tax:/policies:ro \
    -v $(pwd)/opa/config.yaml:/config.yaml:ro \
    openpolicyagent/opa:0.60.0 \
    run --server \
        --config-file=/config.yaml \
        --addr=0.0.0.0:8181 \
        /policies
```

### 2.2 Docker Compose (development)

```yaml
# docker-compose.yml
version: "3.8"

services:
  opa:
    image: openpolicyagent/opa:0.60.0
    command:
      - run
      - --server
      - --config-file=/config.yaml
      - --addr=0.0.0.0:8181
      - /policies
    ports:
      - "8181:8181"
    volumes:
      - ./policies/tax:/policies:ro
      - ./opa/config.dev.yaml:/config.yaml:ro
    environment:
      - OPA_SERVICE_TOKEN=dev-token-placeholder
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8181/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    networks:
      - nexusai-net

  nexusai-core:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OPA_URL=http://opa:8181
    depends_on:
      opa:
        condition: service_healthy
    networks:
      - nexusai-net

networks:
  nexusai-net:
    driver: bridge
```

### 2.3 Docker Compose (production)

```yaml
# docker-compose.prod.yml
version: "3.8"

services:
  opa:
    image: openpolicyagent/opa:0.60.0
    command:
      - run
      - --server
      - --config-file=/config.yaml
      - --addr=0.0.0.0:8181
      - --tls-cert-file=/certs/tls.crt
      - --tls-private-key-file=/certs/tls.key
    ports:
      - "8181:8181"
    volumes:
      - ./opa/config.prod.yaml:/config.yaml:ro
      - ./certs:/certs:ro
    environment:
      - OPA_SERVICE_TOKEN_FILE=/run/secrets/opa_token
    secrets:
      - opa_token
    deploy:
      resources:
        limits:
          cpus: "2"
          memory: 512M
        reservations:
          cpus: "0.5"
          memory: 256M
      replicas: 3
    healthcheck:
      test: ["CMD", "curl", "-fk", "https://localhost:8181/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - nexusai-prod

secrets:
  opa_token:
    external: true

networks:
  nexusai-prod:
    driver: overlay
```

---

## 3. Kubernetes Deployment

### 3.1 Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opa-nexusai
  namespace: nexusai
  labels:
    app: opa
    component: policy-engine
spec:
  replicas: 3
  selector:
    matchLabels:
      app: opa
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: opa
        component: policy-engine
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8181"
    spec:
      serviceAccountName: opa-nexusai
      containers:
        - name: opa
          image: openpolicyagent/opa:0.60.0
          args:
            - run
            - --server
            - --config-file=/config/config.yaml
            - --addr=0.0.0.0:8181
            - /policies
          ports:
            - name: http
              containerPort: 8181
          volumeMounts:
            - name: config
              mountPath: /config
              readOnly: true
            - name: policies
              mountPath: /policies
              readOnly: true
            - name: certs
              mountPath: /certs
              readOnly: true
          env:
            - name: OPA_SERVICE_TOKEN
              valueFrom:
                secretKeyRef:
                  name: opa-secrets
                  key: service-token
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 2000m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 8181
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8181
            initialDelaySeconds: 3
            periodSeconds: 5
      volumes:
        - name: config
          configMap:
            name: opa-config
        - name: policies
          configMap:
            name: opa-policies
        - name: certs
          secret:
            secretName: opa-tls
```

### 3.2 Service

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: opa-nexusai
  namespace: nexusai
  labels:
    app: opa
spec:
  type: ClusterIP
  selector:
    app: opa
  ports:
    - name: http
      port: 8181
      targetPort: 8181
      protocol: TCP
```

### 3.3 ConfigMap — polityki OPA inline

```yaml
# k8s/configmap-policies.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policies
  namespace: nexusai
data:
  _helpers.rego: |
    package tax.helpers
    # ... zawartość _helpers.rego ...
  risk.rego: |
    package tax.risk
    # ... zawartość risk.rego ...
```

> **⚠️ Uwaga:** ConfigMap ma limit 1 MB. Dla większych zestawów polityk użyj OCI Bundle (patrz sekcja 5).

---

## 4. CI/CD Pipeline

### 4.1 GitHub Actions — walidacja i budowa bundle'a

```yaml
# .github/workflows/opa-ci.yml
name: OPA CI/CD

on:
  push:
    paths:
      - "policies/tax/**"
      - "policies/tests/**"
  pull_request:
    paths:
      - "policies/tax/**"

env:
  OPA_VERSION: "0.60.0"

jobs:
  validate:
    name: Validate & Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup OPA
        uses: open-policy-agent/setup-opa@v2
        with:
          version: ${{ env.OPA_VERSION }}

      - name: Check policies
        run: opa check policies/tax/ --strict

      - name: Run tests
        run: opa test policies/tax/ policies/tests/ -v

      - name: Coverage
        run: opa test policies/tax/ policies/tests/ --coverage

      - name: Format check
        run: opa fmt policies/tax/ --diff --check

  build:
    name: Build Bundle
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Setup OPA
        uses: open-policy-agent/setup-opa@v2
        with:
          version: ${{ env.OPA_VERSION }}

      - name: Build bundle
        run: |
          REVISION=$(git rev-parse --short HEAD)
          opa build \
            --bundle policies/tax/ \
            --output tax-bundle-${REVISION}.tar.gz \
            --revision ${REVISION} \
            --entrypoint tax/decide

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: tax-bundle
          path: tax-bundle-*.tar.gz

  publish:
    name: Publish to Registry
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: tax-bundle

      - name: Push to OCI Registry
        run: |
          TAG=$(git rev-parse --short HEAD)
          oras push \
            registry.nexusai.internal/tax-bundle:${TAG} \
            tax-bundle-${TAG}.tar.gz
        env:
          ORAS_USER: ${{ secrets.OCI_USERNAME }}
          ORAS_PASS: ${{ secrets.OCI_PASSWORD }}

  deploy:
    name: Deploy to Staging
    needs: publish
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Trigger OPA reload
        run: |
          TAG=$(git rev-parse --short HEAD)
          curl -X PUT \
            -H "Authorization: Bearer ${{ secrets.OPA_DEPLOY_TOKEN }}" \
            https://opa-staging.nexusai.internal/v1/bundles/nexusai_tax \
            -d "{\"resource\": \"registry.nexusai.internal/tax-bundle:${TAG}\"}"
```

### 4.2 Pre-commit hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: opa-check
        name: OPA Check
        entry: ./bin/opa check policies/tax/ --strict
        language: system
        files: \.rego$
        pass_filenames: false

      - id: opa-test
        name: OPA Test
        entry: ./bin/opa test policies/tax/ policies/tests/ -v
        language: system
        files: \.rego$
        pass_filenames: false

      - id: opa-fmt
        name: OPA Format
        entry: ./bin/opa fmt policies/tax/ --write
        language: system
        files: \.rego$
        pass_filenames: false
```

---

## 5. OCI Bundle Deployment

### 5.1 Rejestracja bundle'a w OCI

```bash
# 1. Budowa bundle
opa build \
    --bundle policies/tax/ \
    --output bundle.tar.gz \
    --revision $(git rev-parse HEAD) \
    --entrypoint tax/decide

# 2. Push do OCI
oras push registry.nexusai.internal/tax-bundle:v1.2.3 bundle.tar.gz

# 3. Konfiguracja OPA do OCI
cat > opa/oci-config.yaml << 'EOF'
services:
  oci_registry:
    url: https://registry.nexusai.internal
    type: oci
    credentials:
      bearer:
        token: "${OCI_TOKEN}"

bundles:
  nexusai_tax:
    service: oci_registry
    resource: registry.nexusai.internal/tax-bundle:v1.2.3
    polling:
      min_delay_seconds: 30
      max_delay_seconds: 60
EOF
```

### 5.2 Hot-reload bez downtime'u

```bash
# OPA ładuje nowy bundle przez polling (co 30s sprawdza nowy revision)
# lub przez API:

# Ręczne przeładowanie:
curl -X PUT \
    http://localhost:8181/v1/bundles/nexusai_tax \
    -d '{"resource": "registry.nexusai.internal/tax-bundle:v1.2.4"}'
```

### 5.3 Rollback

```bash
# Powrót do poprzedniej wersji bundle'a
curl -X PUT \
    http://localhost:8181/v1/bundles/nexusai_tax \
    -d '{"resource": "registry.nexusai.internal/tax-bundle:v1.2.3"}'
```

---

## 6. Monitoring i Alerty

### 6.1 Prometheus — alerty

```yaml
# prometheus/alerts.yml
groups:
  - name: opa_alerts
    rules:
      - alert: OPAHighErrorRate
        expr: |
          rate(opa_policy_eval_error_count[5m]) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "OPA error rate > 1%"
          description: "OPA instance {{ $labels.instance }} has error rate {{ $value }}"

      - alert: OPAHighLatency
        expr: |
          histogram_quantile(0.99,
            rate(opa_policy_eval_latency_milliseconds_bucket[5m])
          ) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "OPA P99 latency > 10ms"

      - alert: OPABundleStale
        expr: |
          time() - opa_bundle_last_activation_timestamp > 3600
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "OPA bundle nie był aktualizowany > 1h"

      - alert: OPAInstanceDown
        expr: up{job="opa-nexusai"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "OPA instance {{ $labels.instance }} is down"
```

### 6.2 Grafana Dashboard (kluczowe panele)

| Panel | Metryka | Próg |
|---|---|---|
| Ewaluacje/sek | `rate(opa_policy_eval_count[1m])` | — |
| P99 latency | `histogram_quantile(0.99, ...)` | < 10ms |
| Error rate | `rate(opa_policy_eval_error_count[5m])` | < 0.1% |
| Decision log buffer | `opa_decision_log_buffer_length` | < 1000 |
| Bundle age | `time() - opa_bundle_last_activation_timestamp` | < 3600s |

---

## 7. Load Testing

### 7.1 Locust — test obciążeniowy

```python
# tests/performance/opa_locustfile.py
from locust import HttpUser, task, between
import random

TAX_INPUTS = [
    # Paliwo PL — powinien trafić P52 (GTU_04)
    {
        "invoice": {
            "category_code": "FUEL",
            "transaction_date": "2026-07-07",
            "amount_net": 10000.00,
            "amount_net_grosze": 1000000,
            "amount_gross": 12300.00,
            "amount_gross_grosze": 1230000,
            "currency": "PLN"
        },
        "vendor": {"country": "PL", "vat_status": "active", "nip": "1234567890", "on_whitelist": True},
        "company": {"tax_form": "CIT_STANDARD", "zus_status": "STANDARD", "is_vat_payer": True},
        "confidence": {"fc_minimum": 0.98, "fc_vat_rate": 0.99, "fc_total_net": 0.98, "fc_vendor_nip": 0.99},
        "thresholds": {"rates": {"vat_standard": "0.23"}, "mpp_limit": 15000}
    },
    # Import z UE (reverse charge) — powinien trafić P40
    {
        "invoice": {
            "category_code": "IT_EQUIPMENT",
            "transaction_date": "2026-07-07",
            "amount_net": 25000.00,
            "amount_net_grosze": 2500000,
            "amount_gross": 30750.00,
            "amount_gross_grosze": 3075000,
            "currency": "EUR"
        },
        "vendor": {"country": "EU", "vat_status": "active", "nip": "DE123456789", "on_whitelist": False},
        "company": {"tax_form": "CIT_STANDARD", "zus_status": "STANDARD", "is_vat_payer": True},
        "confidence": {"fc_minimum": 0.97, "fc_vat_rate": 0.98, "fc_total_net": 0.97, "fc_vendor_nip": 0.99},
        "thresholds": {"rates": {"vat_standard": "0.23"}, "mpp_limit": 15000}
    },
]


class OpaUser(HttpUser):
    wait_time = between(0.05, 0.2)

    @task
    def evaluate_tax(self):
        """Ewaluacja reguł podatkowych."""
        input_data = random.choice(TAX_INPUTS)
        self.client.post(
            "/v1/data/tax/decide",
            json={"input": input_data},
            headers={"Content-Type": "application/json"},
        )

    @task(2)
    def evaluate_risk(self):
        """Ewaluacja reguł ryzyka (najczęściej używane)."""
        input_data = random.choice(TAX_INPUTS)
        self.client.post(
            "/v1/data/tax/risk/decide",
            json={"input": input_data},
            headers={"Content-Type": "application/json"},
        )
```

```bash
# Uruchomienie testu
locust -f tests/performance/opa_locustfile.py \
    --host=http://localhost:8181 \
    --users=100 \
    --spawn-rate=10 \
    --run-time=5m
```

### 7.2 Docelowe SLA

| Metryka | Target |
|---|---|
| Throughput | ≥ 500 ewaluacji/sek na instancję |
| P50 latency | < 1 ms |
| P99 latency | < 5 ms |
| Error rate | < 0.01% |
| Bundle activation | < 500 ms |
| Availability | 99.99% |

---

## 8. Disaster Recovery

### 8.1 Circuit Breaker (Python)

```python
import asyncio
from dataclasses import dataclass, field
from datetime import datetime, timedelta

@dataclass
class OpaCircuitBreaker:
    """Circuit breaker dla OPA — fallback do cache'a reguł."""

    failure_threshold: int = 5
    recovery_timeout: float = 30.0  # sekundy
    half_open_max: int = 3

    failures: int = 0
    half_open_successes: int = 0
    state: str = "CLOSED"  # CLOSED | OPEN | HALF_OPEN
    last_failure: datetime | None = None
    rule_cache: dict = field(default_factory=dict)

    async def evaluate(self, opa_client, input_data):
        """Ewaluacja z circuit breakerem."""
        if self.state == "OPEN":
            if self._should_attempt_recovery():
                self.state = "HALF_OPEN"
                self.half_open_successes = 0
            else:
                return self._fallback(input_data)

        try:
            result = await opa_client.evaluate("tax/decide", input_data)
            self._on_success(input_data, result)
            return result
        except Exception as e:
            self._on_failure()
            return self._fallback(input_data)

    def _on_success(self, input_data, result):
        self.failures = 0
        if self.state == "HALF_OPEN":
            self.half_open_successes += 1
            if self.half_open_successes >= self.half_open_max:
                self.state = "CLOSED"
        # Cache result
        key = self._cache_key(input_data)
        self.rule_cache[key] = result

    def _on_failure(self):
        self.failures += 1
        self.last_failure = datetime.now()
        if self.failures >= self.failure_threshold:
            self.state = "OPEN"

    def _should_attempt_recovery(self) -> bool:
        if self.last_failure is None:
            return True
        elapsed = (datetime.now() - self.last_failure).total_seconds()
        return elapsed >= self.recovery_timeout

    def _fallback(self, input_data):
        key = self._cache_key(input_data)
        if key in self.rule_cache:
            return self.rule_cache[key]
        # Hardcoded fallback: domyślna stawka PL 23%
        return {
            "matched": True,
            "rule_id": "tax.fallback.circuit_breaker",
            "vat_rate": "0.23",
            "rounding_level": "position",
            "income_tax_qualification": "deductible_full",
            "_routing": "TRIAGE_QUEUE",
            "_routing_reason": "OPA niedostępne — fallback do stawki domyślnej",
        }

    def _cache_key(self, input_data) -> str:
        return f"{input_data['invoice']['category_code']}:{input_data['vendor']['country']}"
```

### 8.2 Backup plan

1. **OPA niedostępne:** Circuit breaker → cache reguł → hardcoded fallback
2. **Bundle corrupted:** Rollback do poprzedniej wersji OCI
3. **Thresholds nieaktualne:** Sprawdzenie `valid_from`/`valid_to` w DuckDB przed ewaluacją
4. **Całkowita awaria:** Przełączenie na wbudowany engine reguł Python (uproszczona wersja)

---

## 9. Checklist wdrożenia produkcyjnego

- [ ] **Docker image:** `openpolicyagent/opa:0.60.0` (pinned, nie `latest`)
- [ ] **Readiness probe:** `/health` z timeout 3s
- [ ] **Liveness probe:** `/health` z timeout 5s
- [ ] **Resources:** min 256Mi RAM, 250m CPU
- [ ] **Replikacja:** min 3 instancje (HA)
- [ ] **Bundle:** OCI registry z revision tagowaniem
- [ ] **TLS:** Certyfikat dla komunikacji mTLS
- [ ] **Token:** Service token przez Kubernetes Secret
- [ ] **Decision logs:** Batchowane, max 1 MB buffer
- [ ] **Metrics:** Prometheus scraping włączony
- [ ] **Alerts:** Error rate, latency, bundle staleness
- [ ] **Rollback:** Procedura OCI tag switch
- [ ] **Circuit breaker:** Python fallback w NexusAI Core
- [ ] **Load test:** Min. 500 req/s per instance
- [ ] **Pipeline:** CI/CD z `opa check --strict` + `opa test` + `opa fmt --check`

---

> **Następny krok:** Wdrożenie zgodnie z `17_IMPLEMENTATION_ROADMAP.md` — rozpocznij od M1: MVP (Faza 0-2, 3 tygodnie).
