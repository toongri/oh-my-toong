# Concurrency Test

Concurrency tests verify that **data integrity is maintained under concurrent access** and that locking/synchronization mechanisms work correctly.

## Naming Convention Examples

```kotlin
@DisplayName("동일한 쿠폰으로 동시에 주문해도 한 번만 사용된다")
fun `same coupon used only once even with concurrent orders`()

@DisplayName("동시에 재고 차감해도 정확하게 차감된다")
fun `stock deducted correctly with concurrent orders`()
```

## Characteristics

- Uses `ExecutorService` with multiple threads
- Verifies that only one request succeeds (or all succeed with correct state)
- Tests optimistic/pessimistic locking behavior
- Separate file: `*ConcurrencyTest.kt`

## When to Write Concurrency Tests

- Single resource contention (coupon usage, seat reservation)
- Shared resource updates (stock deduction, balance changes)
- Duplicate prevention with idempotency keys
- Optimistic locking retry scenarios

## File Naming

All concurrency tests must be in separate files named `*ConcurrencyTest.kt`.

This separation is intentional:
- Concurrency tests are often flaky and need special attention
- They require different setup (thread pools, latches)
- Failure debugging is different from regular integration tests

## Test Structure

```kotlin
@SpringBootTest
class OrderConcurrencyTest {

    @Autowired
    private lateinit var orderFacade: OrderFacade

    @Autowired
    private lateinit var databaseCleanUp: DatabaseCleanUp

    @AfterEach
    fun tearDown() {
        databaseCleanUp.truncateAllTables()
    }

    // Test methods...
}
```

## Best Practice Examples

### Single Resource Contention (Coupon)

```kotlin
@DisplayName("동일한 쿠폰으로 여러 기기에서 동시에 주문해도, 쿠폰은 단 한번만 사용되어야 한다")
@Test
fun `same coupon can only be used once even with concurrent orders`() {
    // given
    val userId = 1L
    val product = createProduct(price = Money.krw(10000))
    val coupon = createCoupon(discountType = DiscountType.FIXED_AMOUNT, discountValue = 5000)
    val issuedCoupon = createIssuedCoupon(userId = userId, coupon = coupon)
    createPointAccount(userId = userId)

    val threadCount = 5
    val executorService = Executors.newFixedThreadPool(threadCount)
    val latch = CountDownLatch(threadCount)
    val successCount = AtomicInteger(0)
    val failureCount = AtomicInteger(0)

    // when
    repeat(threadCount) {
        executorService.submit {
            try {
                val criteria = OrderCriteria.PlaceOrder(
                    userId = userId,
                    items = listOf(OrderCriteria.PlaceOrderItem(productId = product.id, quantity = 1)),
                    usePoint = Money.krw(5000),
                    issuedCouponId = issuedCoupon.id,
                )
                orderFacade.placeOrder(criteria)
                successCount.incrementAndGet()
            } catch (e: Exception) {
                failureCount.incrementAndGet()
            } finally {
                latch.countDown()
            }
        }
    }

    latch.await()
    executorService.shutdown()

    // then
    assertThat(successCount.get()).isEqualTo(1)
    assertThat(failureCount.get()).isEqualTo(threadCount - 1)

    val updatedIssuedCoupon = issuedCouponRepository.findById(issuedCoupon.id)!!
    assertThat(updatedIssuedCoupon.status).isEqualTo(UsageStatus.USED)
}
```

### Shared Resource Deduction (Stock)

```kotlin
@DisplayName("동일한 상품에 대해 여러 주문이 동시에 요청되어도, 재고가 정상적으로 차감되어야 한다")
@Test
fun `concurrent orders for same product should deduct stock correctly`() {
    // given
    val initialStock = 10
    val product = createProduct(stockQuantity = initialStock)

    val threadCount = 10
    val executorService = Executors.newFixedThreadPool(threadCount)
    val latch = CountDownLatch(threadCount)
    val successCount = AtomicInteger(0)

    repeat(threadCount) { index ->
        val userId = index + 1L
        createPointAccount(userId = userId)
    }

    // when
    repeat(threadCount) { index ->
        executorService.submit {
            try {
                val userId = index + 1L
                val criteria = OrderCriteria.PlaceOrder(
                    userId = userId,
                    items = listOf(OrderCriteria.PlaceOrderItem(productId = product.id, quantity = 1)),
                    usePoint = product.price,
                    issuedCouponId = null,
                )
                orderFacade.placeOrder(criteria)
                successCount.incrementAndGet()
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                latch.countDown()
            }
        }
    }

    latch.await()
    executorService.shutdown()

    // then
    assertThat(successCount.get()).isEqualTo(initialStock)

    val updatedStock = stockRepository.findByProductId(product.id)!!
    assertThat(updatedStock.quantity).isEqualTo(0)
}
```

### Idempotency with Concurrent Duplicates

```kotlin
@DisplayName("동일한 멱등성 키로 동시에 여러 요청이 와도 하나만 처리된다")
@Test
fun `only one request processed when concurrent requests with same idempotency key`() {
    // given
    val userId = 1L
    val idempotencyKey = UUID.randomUUID().toString()
    val product = createProduct(stockQuantity = 100)
    createPointAccount(userId = userId, balance = Money.krw(100000))

    val threadCount = 5
    val executorService = Executors.newFixedThreadPool(threadCount)
    val latch = CountDownLatch(threadCount)
    val results = ConcurrentHashMap<Int, Result<OrderInfo>>()

    // when
    repeat(threadCount) { index ->
        executorService.submit {
            try {
                val criteria = OrderCriteria.PlaceOrder(
                    userId = userId,
                    idempotencyKey = idempotencyKey,
                    items = listOf(OrderCriteria.PlaceOrderItem(productId = product.id, quantity = 1)),
                    usePoint = Money.krw(10000),
                    issuedCouponId = null,
                )
                val result = orderFacade.placeOrder(criteria)
                results[index] = Result.success(result)
            } catch (e: Exception) {
                results[index] = Result.failure(e)
            } finally {
                latch.countDown()
            }
        }
    }

    latch.await()
    executorService.shutdown()

    // then - all requests should return the same order ID
    val successResults = results.values.filter { it.isSuccess }.map { it.getOrThrow() }
    assertThat(successResults).isNotEmpty()
    assertThat(successResults.map { it.orderId }.distinct()).hasSize(1)

    // stock should only be deducted by 1
    val updatedStock = stockRepository.findByProductId(product.id)!!
    assertThat(updatedStock.quantity).isEqualTo(99)
}
```

## CRITICAL: Assertion After latch.await()

If you assert before `latch.await()`, you're verifying state before all threads complete, causing race conditions. Always assert final state AFTER `latch.await()`.

```kotlin
// ❌ WRONG: assertion before await
repeat(threadCount) { executorService.submit { ... } }
assertThat(successCount.get()).isEqualTo(1)  // threads still running!
latch.await()

// ✅ CORRECT: assertion after await
repeat(threadCount) { executorService.submit { ... } }
latch.await()  // wait for all threads to complete
assertThat(successCount.get()).isEqualTo(1)  // now safe
```

## Common Patterns

### Thread Pool Setup

```kotlin
val threadCount = 10
val executorService = Executors.newFixedThreadPool(threadCount)
val latch = CountDownLatch(threadCount)
val successCount = AtomicInteger(0)
val failureCount = AtomicInteger(0)
```

### Execution Block

```kotlin
repeat(threadCount) { index ->
    executorService.submit {
        try {
            // Business operation
            successCount.incrementAndGet()
        } catch (e: Exception) {
            failureCount.incrementAndGet()
        } finally {
            latch.countDown()
        }
    }
}

latch.await()
executorService.shutdown()
```

### Assertions

```kotlin
// For single-winner scenarios (coupon, seat)
assertThat(successCount.get()).isEqualTo(1)
assertThat(failureCount.get()).isEqualTo(threadCount - 1)

// For all-success scenarios (stock until depleted)
assertThat(successCount.get()).isEqualTo(initialStock)

// Always verify final state
val finalState = repository.findById(id)!!
assertThat(finalState.field).isEqualTo(expectedValue)
```

## Timeout Handling

Always set timeouts to prevent hanging tests:

```kotlin
// Option 1: Latch timeout
val completed = latch.await(30, TimeUnit.SECONDS)
assertThat(completed).isTrue()  // Fail if threads hung

// Option 2: Executor timeout
executorService.shutdown()
val terminated = executorService.awaitTermination(30, TimeUnit.SECONDS)
assertThat(terminated).isTrue()

// Option 3: JUnit timeout (entire test)
@Test
@Timeout(60)  // Fail after 60 seconds
fun `concurrent test with timeout`() { ... }
```

## Debugging Tips

1. **Use `e.printStackTrace()`** in catch blocks during development
2. **Increase thread count** to make race conditions more likely
3. **Add small delays** if you need to control timing
4. **Check database locks** - some DBs have different locking behaviors
5. **Run multiple times** - flaky tests may pass sometimes
6. **Set timeouts** - prevent tests from hanging indefinitely

## Quality Checklist

- [ ] Test file is named `*ConcurrencyTest.kt`
- [ ] Uses `CountDownLatch` for synchronization
- [ ] Uses `AtomicInteger` for thread-safe counting
- [ ] Verifies both success/failure counts
- [ ] Verifies final state after all threads complete
- [ ] `executorService.shutdown()` is called
- [ ] Database cleanup in `@AfterEach`
