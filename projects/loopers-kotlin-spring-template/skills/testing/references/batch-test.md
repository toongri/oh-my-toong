# Batch Test

Batch tests verify that **Spring Batch pipeline components are correctly wired together**.

## Core Philosophy

Spring Batch components (Reader/Processor/Writer) are **infrastructure layer**, not domain layer.

- **Business logic belongs in Domain model**, not in Processor
- Domain models are already tested via Unit Tests
- Batch tests verify **"does the pipeline work end-to-end?"**, not business logic

```
┌─────────────────────────────────────────────────────────┐
│  Spring Batch (Infrastructure)                          │
│  Reader → Processor → Writer                            │
│           (calls domain model)                        │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
          ┌───────────────┐
          │ Domain Layer  │  ← Already tested via Unit Test
          └───────────────┘
```

## What to Test

| Component                            | Test? | Reason                                      |
|--------------------------------------|-------|---------------------------------------------|
| Reader (JdbcCursorItemReader, etc.)  | ❌     | Framework component, query tested elsewhere |
| Processor with business logic inside | ❌     | Anti-pattern. Move logic to Domain Model    |
| Processor calling Domain Model       | ❌     | Domain Model already unit tested            |
| Writer (JdbcBatchItemWriter, etc.)   | ❌     | Framework component                         |
| **Step end-to-end**                  | ✅     | Verify pipeline wiring works                |
| **Job with conditional flow**        | ✅     | Only if Decider or complex branching exists |

## Step Integration Test (Primary Pattern)

This is the **main test pattern** for batch jobs. Verify the pipeline produces correct final state.

```kotlin
@SpringBatchTest
@SpringBootTest
@DisplayName("SettlementStep Integration Test")
class SettlementStepIntegrationTest {

    @Autowired
    private lateinit var jobLauncherTestUtils: JobLauncherTestUtils

    @Autowired
    private lateinit var orderRepository: OrderRepository

    @Autowired
    private lateinit var databaseCleanUp: DatabaseCleanUp

    @Autowired
    private lateinit var job: Job

    @BeforeEach
    fun setUp() {
        jobLauncherTestUtils.job = job
    }

    @AfterEach
    fun tearDown() {
        databaseCleanUp.truncateAllTables()
    }

    @Test
    @DisplayName("Step completes and all PAID orders become SETTLED")
    fun `all PAID orders become SETTLED after step completion`() {
        // given
        repeat(5) { createOrder(status = OrderStatus.PAID) }
        repeat(3) { createOrder(status = OrderStatus.CANCELLED) }

        // when
        val jobExecution = jobLauncherTestUtils.launchStep("settlementStep")

        // then
        assertThat(jobExecution.exitStatus.exitCode).isEqualTo("COMPLETED")
        assertThat(orderRepository.findByStatus(OrderStatus.SETTLED)).hasSize(5)
    }

    @Test
    @DisplayName("Step completes even when no orders to process")
    fun `step completes when no orders to process`() {
        // given - no PAID orders

        // when
        val jobExecution = jobLauncherTestUtils.launchStep("settlementStep")

        // then
        assertThat(jobExecution.exitStatus.exitCode).isEqualTo("COMPLETED")
        assertThat(jobExecution.stepExecutions.first().readCount).isEqualTo(0)
    }

    private fun createOrder(status: OrderStatus): Order {
        return orderRepository.save(Order.create(status = status))
    }
}
```

## Job Integration Test (Only for Complex Branching)

Only write Job-level tests when there's **conditional flow logic** (Decider, `on("FAILED")`).

```kotlin
@Test
@DisplayName("Job fails when input file is missing")
fun `job fails when input file is missing`() {
    // given
    val jobParameters = JobParametersBuilder()
        .addString("inputFile", "/non/existent/path.csv")
        .addLong("timestamp", System.currentTimeMillis())
        .toJobParameters()

    // when
    val jobExecution = jobLauncherTestUtils.launchJob(jobParameters)

    // then
    assertThat(jobExecution.exitStatus.exitCode).isEqualTo("FAILED")
}
```

## When to Write Unit Tests for Batch Components

Only in rare cases where Processor/Listener contains **logic that cannot be extracted to Domain Model**:

```kotlin
// Rare case: Listener with batch-specific logic
class NoWorkFoundListenerTest {

    private val listener = NoWorkFoundStepExecutionListener()

    @Test
    @DisplayName("Returns FAILED when read count is zero")
    fun `returns FAILED when read count is zero`() {
        // given
        val stepExecution = MetaDataInstanceFactory.createStepExecution()
        stepExecution.readCount = 0

        // when
        val result = listener.afterStep(stepExecution)

        // then
        assertThat(result.exitCode).isEqualTo(ExitStatus.FAILED.exitCode)
    }
}
```

## Anti-Patterns

### ❌ Testing Processor Business Logic

```kotlin
// Bad: Business logic in Processor
class SettlementProcessorTest {
    @Test
    fun `calculates fee correctly`() {
        val processor = SettlementProcessor()
        val result = processor.process(order)
        assertThat(result.fee).isEqualTo(300)  // This should be in Domain Model test!
    }
}
```

### ❌ Testing Framework Components

```kotlin
// Bad: Testing Spring Batch's FlatFileItemReader
@Test
fun `reader parses CSV correctly`() {
    // This is testing the framework, not your code
}
```

## CRITICAL: Test Isolation

Always clean up batch metadata after tests:

```kotlin
@AfterEach
fun tearDown() {
    jobRepositoryTestUtils.removeJobExecutions()  // Clean batch metadata
    databaseCleanUp.truncateAllTables()           // Clean business tables
}
```

## Summary

1. **Don't test Reader/Processor/Writer individually** - they're infrastructure
2. **Business logic belongs in Domain Models** - test those with Unit Tests
3. **Step Integration Test is the primary pattern** - verify pipeline wiring
4. **Job Integration Test only for branching** - Decider, conditional flows
5. **Clean up batch metadata** - `jobRepositoryTestUtils.removeJobExecutions()`
