# E2E Test

E2E tests verify that **the external interface visible to clients works according to contract**. Focus on HTTP layer and API contract, not on business logic itself.

## Naming Convention Examples

```kotlin
@DisplayName("PG 결제 성공 콜백을 받으면 200 OK를 반환한다")
fun `returns 200 OK when payment callback succeeds`()

@DisplayName("존재하지 않는 orderId로 콜백이 오면 404 Not Found를 반환한다")
fun `returns 404 Not Found when orderId does not exist`()

@DisplayName("인증 헤더 없이 요청하면 401을 반환한다")
fun `returns 401 when authorization header is missing`()
```

## Characteristics

- Uses `TestRestTemplate` or `WebTestClient`
- Verifies HTTP status codes and response structure
- Does NOT verify internal database state
- Focus on API contract, not business logic

## Verification Principle

**Core Question**: "Does the client receive the promised response?"

**What to verify**: HTTP status code, core identifiers in response

**What NOT to verify**: Internal database state, service orchestration details

## Extraction Patterns

| Pattern | Description |
|---------|-------------|
| Success Response | Status code (200, 201), core identifier (id) exists |
| Error Response | Status code on validation failure, not found, business rule violation |
| Auth Failure | Status code when auth header missing or invalid |

## Best Practice Examples

### Success Response

```kotlin
@Test
@DisplayName("주문을 생성하면 200 OK와 주문 ID를 반환한다")
fun returnOrderId_whenOrderIsPlaced() {
    // given
    val userId = 1L
    val product = createProduct(price = Money.krw(20000))
    createPointAccount(userId, Money.krw(50000))
    stubPgPaymentSuccess()

    val request = OrderV1Request.PlaceOrder(
        items = listOf(OrderV1Request.PlaceOrderItem(productId = product.id, quantity = 2)),
        usePoint = 30000,
        cardType = CardType.HYUNDAI,
        cardNo = "1234-5678-9012-3456",
    )

    // when
    val response = placeOrder(userId, request)

    // then - verify status code and core identifier only
    assertThat(response.statusCode).isEqualTo(HttpStatus.OK)
    assertThat(response.body?.data?.orderId).isNotNull()
}
```

### Business Rule Violation → 400

```kotlin
@Test
@DisplayName("포인트가 부족하면 400 Bad Request를 반환한다")
fun returnBadRequest_whenInsufficientPoints() {
    // given
    val userId = 1L
    val product = createProduct(price = Money.krw(20000))
    createPointAccount(userId, Money.krw(5000))

    val request = OrderV1Request.PlaceOrder(
        items = listOf(OrderV1Request.PlaceOrderItem(productId = product.id, quantity = 1)),
        usePoint = 10000,
        cardType = CardType.HYUNDAI,
        cardNo = "1234-5678-9012-3456",
    )

    // when
    val response = placeOrder(userId, request)

    // then
    assertThat(response.statusCode).isEqualTo(HttpStatus.BAD_REQUEST)
}

@Test
@DisplayName("재고가 부족하면 400 Bad Request를 반환한다")
fun returnBadRequest_whenInsufficientStock() {
    // given
    val userId = 1L
    val product = createProduct(price = Money.krw(20000), stockQuantity = 5)
    createPointAccount(userId, Money.krw(100000))

    val request = OrderV1Request.PlaceOrder(
        items = listOf(OrderV1Request.PlaceOrderItem(productId = product.id, quantity = 10)),
        usePoint = 100000,
        cardType = CardType.HYUNDAI,
        cardNo = "1234-5678-9012-3456",
    )

    // when
    val response = placeOrder(userId, request)

    // then
    assertThat(response.statusCode).isEqualTo(HttpStatus.BAD_REQUEST)
}
```

### Not Found → 404

```kotlin
@Test
@DisplayName("존재하지 않는 상품을 주문하면 404 Not Found를 반환한다")
fun returnNotFound_whenProductDoesNotExist() {
    // given
    val userId = 1L
    createPointAccount(userId, Money.krw(100000))

    val request = OrderV1Request.PlaceOrder(
        items = listOf(OrderV1Request.PlaceOrderItem(productId = 999L, quantity = 1)),
        usePoint = 10000,
        cardType = CardType.HYUNDAI,
        cardNo = "1234-5678-9012-3456",
    )

    // when
    val response = placeOrder(userId, request)

    // then
    assertThat(response.statusCode).isEqualTo(HttpStatus.NOT_FOUND)
}
```

### Auth Header Missing → 400

```kotlin
@Test
@DisplayName("X-USER-ID 헤더가 없으면 400 Bad Request를 반환한다")
fun returnBadRequest_whenUserIdHeaderIsMissing() {
    // given
    val product = createProduct()
    val request = OrderV1Request.PlaceOrder(
        items = listOf(OrderV1Request.PlaceOrderItem(productId = product.id, quantity = 1)),
        usePoint = 10000,
        cardType = CardType.HYUNDAI,
        cardNo = "1234-5678-9012-3456",
    )

    // when - pass null as userId
    val response = placeOrder(null, request)

    // then
    assertThat(response.statusCode).isEqualTo(HttpStatus.BAD_REQUEST)
}
```

## Test Setup

```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWireMock(port = 0)
@TestPropertySource(properties = ["pg.base-url=http://localhost:\${wiremock.server.port}"])
@DisplayName("OrderV1Api E2E 테스트")
class OrderV1ApiE2ETest @Autowired constructor(
    private val testRestTemplate: TestRestTemplate,
    private val productRepository: ProductRepository,
    private val stockRepository: StockRepository,
    // ... other repositories
    private val databaseCleanUp: DatabaseCleanUp,
) {

    @AfterEach
    fun tearDown() {
        databaseCleanUp.truncateAllTables()
        reset()  // WireMock reset
    }
}
```

## HTTP Request Helper

```kotlin
private fun placeOrder(
    userId: Long?,
    request: OrderV1Request.PlaceOrder,
): ResponseEntity<ApiResponse<OrderV1Response.PlaceOrder>> {
    val headers = HttpHeaders().apply {
        contentType = MediaType.APPLICATION_JSON
        userId?.let { set("X-USER-ID", it.toString()) }
    }

    return testRestTemplate.exchange(
        "/api/v1/orders",
        HttpMethod.POST,
        HttpEntity(request, headers),
        object : ParameterizedTypeReference<ApiResponse<OrderV1Response.PlaceOrder>>() {},
    )
}
```

## WireMock Stub Helper

```kotlin
private fun stubPgPaymentSuccess() {
    stubFor(
        post(urlEqualTo("/api/v1/payments"))
            .willReturn(
                aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody(
                        """
                        {
                            "meta": {"result": "SUCCESS", "errorCode": null, "message": null},
                            "data": {"transactionKey": "tx_test_${System.currentTimeMillis()}", "status": "PENDING"}
                        }
                        """.trimIndent(),
                    ),
            ),
    )
}
```

## Quality Checklist

- [ ] Status codes for main success scenarios are verified
- [ ] Response body verification is minimized to core identifiers (id, etc.)
- [ ] Authentication/authorization failure cases exist
- [ ] Status codes for main business rule violations are verified (400)
- [ ] Status codes for not found cases are verified (404)
- [ ] Detailed business logic is not verified (belongs to Unit/Integration)
- [ ] WireMock stubs set up for external API dependencies
