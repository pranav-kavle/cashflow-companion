-- CreateEnum
CREATE TYPE "V1Eligibility" AS ENUM ('schedule_c_supported');

-- CreateEnum
CREATE TYPE "BucketKind" AS ENUM ('taxes', 'runway', 'pay', 'savings', 'debt');

-- CreateEnum
CREATE TYPE "FilingStatus" AS ENUM ('single', 'mfj', 'hoh', 'mfs', 'qw');

-- CreateEnum
CREATE TYPE "TaxTreatment" AS ENUM ('schedule_c');

-- CreateEnum
CREATE TYPE "BankProvider" AS ENUM ('plaid', 'teller');

-- CreateEnum
CREATE TYPE "BankConnectionStatus" AS ENUM ('active', 'error', 'stale');

-- CreateEnum
CREATE TYPE "BankAccountType" AS ENUM ('checking', 'savings');

-- CreateEnum
CREATE TYPE "BalanceSnapshotSource" AS ENUM ('aggregator', 'scripted');

-- CreateEnum
CREATE TYPE "ClassificationSource" AS ENUM ('seed', 'model', 'user');

-- CreateEnum
CREATE TYPE "ClassificationLabel" AS ENUM ('income', 'transfer', 'refund', 'repayment', 'loan', 'other', 'fixed_recurring', 'variable_discretionary');

-- CreateEnum
CREATE TYPE "ClassificationCadence" AS ENUM ('retainer', 'project', 'windfall');

-- CreateEnum
CREATE TYPE "ReviewState" AS ENUM ('pending', 'confirmed', 'corrected', 'dismissed');

-- CreateEnum
CREATE TYPE "RecurringExpenseStatus" AS ENUM ('active', 'new', 'changed');

-- CreateEnum
CREATE TYPE "ExpectedIncomeStatus" AS ENUM ('pending', 'late', 'received', 'possible');

-- CreateEnum
CREATE TYPE "TaxQuarter" AS ENUM ('Q1', 'Q2', 'Q3', 'Q4');

-- CreateEnum
CREATE TYPE "TriggerType" AS ENUM ('schedule', 'source_event', 'manual_feedback', 'threshold');

-- CreateEnum
CREATE TYPE "AgentRunStatus" AS ENUM ('running', 'ok', 'retrying', 'error');

-- CreateEnum
CREATE TYPE "PlanRunType" AS ENUM ('seed', 'synthesize', 'replan');

-- CreateEnum
CREATE TYPE "PlanStatus" AS ENUM ('provisional', 'final', 'blocked', 'infeasible');

-- CreateEnum
CREATE TYPE "InputFreshnessStatus" AS ENUM ('fresh', 'stale', 'unknown');

-- CreateEnum
CREATE TYPE "TaxBombStatus" AS ENUM ('funded', 'gap', 'at_risk');

-- CreateEnum
CREATE TYPE "FundedStatus" AS ENUM ('funded', 'partial', 'paused', 'deferred', 'short');

-- CreateEnum
CREATE TYPE "ProjectionKind" AS ENUM ('income', 'runway', 'spend');

-- CreateEnum
CREATE TYPE "PlanWarningCode" AS ENUM ('unresolved_classification', 'stale_feed', 'tax_shortfall', 'floor_breach');

-- CreateEnum
CREATE TYPE "PlanWarningSeverity" AS ENUM ('info', 'warning', 'critical');

-- CreateEnum
CREATE TYPE "AppliedTreatment" AS ENUM ('include', 'exclude', 'hold');

-- CreateEnum
CREATE TYPE "CheckInChannel" AS ENUM ('ui', 'email');

-- CreateEnum
CREATE TYPE "DetectionMethod" AS ENUM ('self_report', 'inferred_txn');

-- CreateTable
CREATE TABLE "user" (
    "id" TEXT NOT NULL,
    "clerk_user_id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "v1_eligibility" "V1Eligibility" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "goal_config" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "version_no" INTEGER NOT NULL,
    "is_current" BOOLEAN NOT NULL,
    "effective_from" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "goal_config_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bucket_target" (
    "id" TEXT NOT NULL,
    "goal_config_id" TEXT NOT NULL,
    "bucket_kind" "BucketKind" NOT NULL,
    "priority_order" INTEGER NOT NULL,
    "target_amount" DECIMAL(14,2) NOT NULL,
    "is_floor" BOOLEAN NOT NULL,
    "floor_amount" DECIMAL(14,2),

    CONSTRAINT "bucket_target_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tax_profile" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "version_no" INTEGER NOT NULL,
    "is_current" BOOLEAN NOT NULL,
    "tax_year" INTEGER NOT NULL,
    "filing_status" "FilingStatus" NOT NULL,
    "tax_treatment" "TaxTreatment" NOT NULL,
    "resident_tax_jurisdiction" TEXT NOT NULL,
    "effective_from" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "tax_profile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_connection" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "provider" "BankProvider" NOT NULL,
    "provider_item_id" TEXT NOT NULL,
    "status" "BankConnectionStatus" NOT NULL,
    "last_synced_at" TIMESTAMP(3),

    CONSTRAINT "bank_connection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bank_account" (
    "id" TEXT NOT NULL,
    "connection_id" TEXT NOT NULL,
    "provider_account_id" TEXT NOT NULL,
    "type" "BankAccountType" NOT NULL,
    "is_commingled" BOOLEAN NOT NULL,

    CONSTRAINT "bank_account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account_balance_snapshot" (
    "id" TEXT NOT NULL,
    "account_id" TEXT NOT NULL,
    "balance" DECIMAL(14,2) NOT NULL,
    "as_of" TIMESTAMP(3) NOT NULL,
    "sync_id" TEXT NOT NULL,
    "source" "BalanceSnapshotSource" NOT NULL,

    CONSTRAINT "account_balance_snapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaction" (
    "id" TEXT NOT NULL,
    "account_id" TEXT NOT NULL,
    "provider_txn_id" TEXT NOT NULL,
    "posted_date" DATE NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "raw_description" TEXT NOT NULL,
    "counterparty" TEXT,
    "channel" TEXT,
    "ingested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaction_classification" (
    "id" TEXT NOT NULL,
    "transaction_id" TEXT NOT NULL,
    "source" "ClassificationSource" NOT NULL,
    "label" "ClassificationLabel" NOT NULL,
    "cadence" "ClassificationCadence",
    "confidence" DECIMAL(5,4),
    "evidence" JSONB,
    "review_state" "ReviewState" NOT NULL,
    "supersedes_id" TEXT,
    "is_current" BOOLEAN NOT NULL,
    "model_version" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transaction_classification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recurring_expense" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "merchant" TEXT NOT NULL,

    CONSTRAINT "recurring_expense_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recurring_expense_version" (
    "id" TEXT NOT NULL,
    "recurring_expense_id" TEXT NOT NULL,
    "version_no" INTEGER NOT NULL,
    "typical_amount" DECIMAL(14,2) NOT NULL,
    "cadence" "ClassificationCadence",
    "status" "RecurringExpenseStatus" NOT NULL,
    "is_current" BOOLEAN NOT NULL,
    "effective_from" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "recurring_expense_version_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recurring_expense_txn" (
    "recurring_expense_version_id" TEXT NOT NULL,
    "transaction_id" TEXT NOT NULL,

    CONSTRAINT "recurring_expense_txn_pkey" PRIMARY KEY ("recurring_expense_version_id","transaction_id")
);

-- CreateTable
CREATE TABLE "expected_income" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "source_name" TEXT NOT NULL,
    "invoice_ref" TEXT NOT NULL,

    CONSTRAINT "expected_income_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "expected_income_version" (
    "id" TEXT NOT NULL,
    "expected_income_id" TEXT NOT NULL,
    "version_no" INTEGER NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "expected_date" DATE NOT NULL,
    "status" "ExpectedIncomeStatus" NOT NULL,
    "received_transaction_id" TEXT,
    "is_current" BOOLEAN NOT NULL,
    "effective_from" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "expected_income_version_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tax_rule_set" (
    "id" TEXT NOT NULL,
    "tax_year" INTEGER NOT NULL,
    "jurisdiction" TEXT NOT NULL,
    "filing_status" "FilingStatus" NOT NULL,
    "se_tax_rate" DECIMAL(6,5) NOT NULL,
    "qbi_params" JSONB NOT NULL,
    "version" INTEGER NOT NULL,
    "source" TEXT NOT NULL,
    "citation" TEXT NOT NULL,
    "source_url" TEXT NOT NULL,
    "published_date" DATE NOT NULL,
    "checksum" TEXT NOT NULL,
    "ingested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tax_rule_set_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tax_bracket" (
    "id" TEXT NOT NULL,
    "tax_rule_set_id" TEXT NOT NULL,
    "lower_bound" DECIMAL(14,2) NOT NULL,
    "upper_bound" DECIMAL(14,2),
    "rate" DECIMAL(6,5) NOT NULL,

    CONSTRAINT "tax_bracket_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tax_due_date" (
    "id" TEXT NOT NULL,
    "tax_year" INTEGER NOT NULL,
    "quarter" "TaxQuarter" NOT NULL,
    "due_date" DATE NOT NULL,
    "jurisdiction" TEXT NOT NULL,

    CONSTRAINT "tax_due_date_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trigger_event" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "trigger_type" "TriggerType" NOT NULL,
    "payload" JSONB NOT NULL,
    "interpreted_as" JSONB,
    "idempotency_key" TEXT NOT NULL,
    "provider_event_id" TEXT,
    "received_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trigger_event_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agent_run" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "trigger_event_id" TEXT NOT NULL,
    "status" "AgentRunStatus" NOT NULL,
    "langfuse_trace_id" TEXT,
    "token_cost" DECIMAL(10,4),
    "surfaced" BOOLEAN NOT NULL DEFAULT false,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finished_at" TIMESTAMP(3),

    CONSTRAINT "agent_run_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agent_run_attempt" (
    "id" TEXT NOT NULL,
    "agent_run_id" TEXT NOT NULL,
    "attempt_no" INTEGER NOT NULL,
    "status" "AgentRunStatus" NOT NULL,
    "error_code" TEXT,
    "error_message" TEXT,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finished_at" TIMESTAMP(3),

    CONSTRAINT "agent_run_attempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plan" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "agent_run_id" TEXT NOT NULL,
    "goal_config_id" TEXT NOT NULL,
    "tax_profile_id" TEXT NOT NULL,
    "run_type" "PlanRunType" NOT NULL,
    "plan_status" "PlanStatus" NOT NULL,
    "input_freshness_status" "InputFreshnessStatus" NOT NULL,
    "engine_version" TEXT NOT NULL,
    "engine_build_sha" TEXT NOT NULL,
    "safe_to_pay_low" DECIMAL(14,2) NOT NULL,
    "safe_to_pay_high" DECIMAL(14,2) NOT NULL,
    "promised_number" DECIMAL(14,2) NOT NULL,
    "tax_bomb_status" "TaxBombStatus" NOT NULL,
    "tax_gap_amount" DECIMAL(14,2),
    "runway_months" DECIMAL(6,2),
    "applied_forecast_params" JSONB NOT NULL,
    "assumptions" JSONB NOT NULL,
    "input_digest" TEXT NOT NULL,
    "input_digest_algo" TEXT NOT NULL,
    "input_digest_spec_version" TEXT NOT NULL,
    "output_digest" TEXT NOT NULL,
    "output_digest_algo" TEXT NOT NULL,
    "output_digest_spec_version" TEXT NOT NULL,
    "debug_input_payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "plan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "allocation_line" (
    "id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "bucket_kind" "BucketKind" NOT NULL,
    "priority_order_used" INTEGER NOT NULL,
    "target_amount" DECIMAL(14,2) NOT NULL,
    "floor_amount" DECIMAL(14,2),
    "allocated_amount" DECIMAL(14,2) NOT NULL,
    "shortfall_amount" DECIMAL(14,2),
    "funded_status" "FundedStatus" NOT NULL,

    CONSTRAINT "allocation_line_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "projection" (
    "id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "kind" "ProjectionKind" NOT NULL,
    "low" DECIMAL(14,2) NOT NULL,
    "high" DECIMAL(14,2) NOT NULL,
    "point" DECIMAL(14,2) NOT NULL,
    "assumption" TEXT NOT NULL,

    CONSTRAINT "projection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plan_warning" (
    "id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "code" "PlanWarningCode" NOT NULL,
    "severity" "PlanWarningSeverity" NOT NULL,
    "subject_ref" TEXT,
    "message" TEXT NOT NULL,

    CONSTRAINT "plan_warning_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plan_input_classification" (
    "plan_id" TEXT NOT NULL,
    "classification_id" TEXT NOT NULL,
    "applied_treatment" "AppliedTreatment" NOT NULL,
    "included_amount" DECIMAL(14,2),
    "policy_rule_code" TEXT,

    CONSTRAINT "plan_input_classification_pkey" PRIMARY KEY ("plan_id","classification_id")
);

-- CreateTable
CREATE TABLE "plan_input_expected_income" (
    "plan_id" TEXT NOT NULL,
    "expected_income_version_id" TEXT NOT NULL,
    "included_amount" DECIMAL(14,2),

    CONSTRAINT "plan_input_expected_income_pkey" PRIMARY KEY ("plan_id","expected_income_version_id")
);

-- CreateTable
CREATE TABLE "plan_input_recurring_expense" (
    "plan_id" TEXT NOT NULL,
    "recurring_expense_version_id" TEXT NOT NULL,

    CONSTRAINT "plan_input_recurring_expense_pkey" PRIMARY KEY ("plan_id","recurring_expense_version_id")
);

-- CreateTable
CREATE TABLE "plan_input_balance_snapshot" (
    "plan_id" TEXT NOT NULL,
    "balance_snapshot_id" TEXT NOT NULL,

    CONSTRAINT "plan_input_balance_snapshot_pkey" PRIMARY KEY ("plan_id","balance_snapshot_id")
);

-- CreateTable
CREATE TABLE "plan_input_tax_rule_set" (
    "plan_id" TEXT NOT NULL,
    "tax_rule_set_id" TEXT NOT NULL,

    CONSTRAINT "plan_input_tax_rule_set_pkey" PRIMARY KEY ("plan_id","tax_rule_set_id")
);

-- CreateTable
CREATE TABLE "check_in" (
    "id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "agent_run_id" TEXT NOT NULL,
    "decision_text" TEXT NOT NULL,
    "what_changed" TEXT,
    "materiality_reason" TEXT,
    "channel" "CheckInChannel" NOT NULL,
    "response" JSONB,
    "resulting_classification_id" TEXT,
    "responded_at" TIMESTAMP(3),

    CONSTRAINT "check_in_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recommendation_outcome" (
    "id" TEXT NOT NULL,
    "plan_id" TEXT NOT NULL,
    "recommended_amount" DECIMAL(14,2) NOT NULL,
    "acted" BOOLEAN,
    "observed_amount" DECIMAL(14,2),
    "detection_method" "DetectionMethod",
    "confidence" DECIMAL(5,4),
    "observed_at" TIMESTAMP(3),

    CONSTRAINT "recommendation_outcome_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "user_clerk_user_id_key" ON "user"("clerk_user_id");

-- CreateIndex
CREATE INDEX "goal_config_user_id_idx" ON "goal_config"("user_id");

-- CreateIndex
CREATE INDEX "bucket_target_goal_config_id_idx" ON "bucket_target"("goal_config_id");

-- CreateIndex
CREATE INDEX "tax_profile_user_id_idx" ON "tax_profile"("user_id");

-- CreateIndex
CREATE INDEX "bank_connection_user_id_idx" ON "bank_connection"("user_id");

-- CreateIndex
CREATE INDEX "bank_account_connection_id_idx" ON "bank_account"("connection_id");

-- CreateIndex
CREATE INDEX "account_balance_snapshot_account_id_idx" ON "account_balance_snapshot"("account_id");

-- CreateIndex
CREATE INDEX "transaction_account_id_idx" ON "transaction"("account_id");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_account_id_provider_txn_id_key" ON "transaction"("account_id", "provider_txn_id");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_classification_supersedes_id_key" ON "transaction_classification"("supersedes_id");

-- CreateIndex
CREATE INDEX "transaction_classification_transaction_id_idx" ON "transaction_classification"("transaction_id");

-- CreateIndex
CREATE INDEX "recurring_expense_user_id_idx" ON "recurring_expense"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "recurring_expense_user_id_merchant_key" ON "recurring_expense"("user_id", "merchant");

-- CreateIndex
CREATE INDEX "recurring_expense_version_recurring_expense_id_idx" ON "recurring_expense_version"("recurring_expense_id");

-- CreateIndex
CREATE INDEX "expected_income_user_id_idx" ON "expected_income"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "expected_income_user_id_invoice_ref_key" ON "expected_income"("user_id", "invoice_ref");

-- CreateIndex
CREATE INDEX "expected_income_version_expected_income_id_idx" ON "expected_income_version"("expected_income_id");

-- CreateIndex
CREATE UNIQUE INDEX "tax_rule_set_tax_year_jurisdiction_filing_status_version_key" ON "tax_rule_set"("tax_year", "jurisdiction", "filing_status", "version");

-- CreateIndex
CREATE INDEX "tax_bracket_tax_rule_set_id_idx" ON "tax_bracket"("tax_rule_set_id");

-- CreateIndex
CREATE UNIQUE INDEX "tax_due_date_tax_year_quarter_jurisdiction_key" ON "tax_due_date"("tax_year", "quarter", "jurisdiction");

-- CreateIndex
CREATE UNIQUE INDEX "trigger_event_idempotency_key_key" ON "trigger_event"("idempotency_key");

-- CreateIndex
CREATE INDEX "trigger_event_user_id_idx" ON "trigger_event"("user_id");

-- CreateIndex
CREATE INDEX "agent_run_user_id_idx" ON "agent_run"("user_id");

-- CreateIndex
CREATE INDEX "agent_run_trigger_event_id_idx" ON "agent_run"("trigger_event_id");

-- CreateIndex
CREATE UNIQUE INDEX "agent_run_attempt_agent_run_id_attempt_no_key" ON "agent_run_attempt"("agent_run_id", "attempt_no");

-- CreateIndex
CREATE INDEX "plan_user_id_idx" ON "plan"("user_id");

-- CreateIndex
CREATE INDEX "plan_agent_run_id_idx" ON "plan"("agent_run_id");

-- CreateIndex
CREATE INDEX "allocation_line_plan_id_idx" ON "allocation_line"("plan_id");

-- CreateIndex
CREATE INDEX "projection_plan_id_idx" ON "projection"("plan_id");

-- CreateIndex
CREATE INDEX "plan_warning_plan_id_idx" ON "plan_warning"("plan_id");

-- CreateIndex
CREATE INDEX "check_in_plan_id_idx" ON "check_in"("plan_id");

-- CreateIndex
CREATE INDEX "check_in_agent_run_id_idx" ON "check_in"("agent_run_id");

-- CreateIndex
CREATE UNIQUE INDEX "recommendation_outcome_plan_id_key" ON "recommendation_outcome"("plan_id");

-- AddForeignKey
ALTER TABLE "goal_config" ADD CONSTRAINT "goal_config_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bucket_target" ADD CONSTRAINT "bucket_target_goal_config_id_fkey" FOREIGN KEY ("goal_config_id") REFERENCES "goal_config"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tax_profile" ADD CONSTRAINT "tax_profile_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_connection" ADD CONSTRAINT "bank_connection_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bank_account" ADD CONSTRAINT "bank_account_connection_id_fkey" FOREIGN KEY ("connection_id") REFERENCES "bank_connection"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_balance_snapshot" ADD CONSTRAINT "account_balance_snapshot_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "bank_account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction" ADD CONSTRAINT "transaction_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "bank_account"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction_classification" ADD CONSTRAINT "transaction_classification_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "transaction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction_classification" ADD CONSTRAINT "transaction_classification_supersedes_id_fkey" FOREIGN KEY ("supersedes_id") REFERENCES "transaction_classification"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recurring_expense" ADD CONSTRAINT "recurring_expense_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recurring_expense_version" ADD CONSTRAINT "recurring_expense_version_recurring_expense_id_fkey" FOREIGN KEY ("recurring_expense_id") REFERENCES "recurring_expense"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recurring_expense_txn" ADD CONSTRAINT "recurring_expense_txn_recurring_expense_version_id_fkey" FOREIGN KEY ("recurring_expense_version_id") REFERENCES "recurring_expense_version"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recurring_expense_txn" ADD CONSTRAINT "recurring_expense_txn_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "transaction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expected_income" ADD CONSTRAINT "expected_income_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expected_income_version" ADD CONSTRAINT "expected_income_version_expected_income_id_fkey" FOREIGN KEY ("expected_income_id") REFERENCES "expected_income"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expected_income_version" ADD CONSTRAINT "expected_income_version_received_transaction_id_fkey" FOREIGN KEY ("received_transaction_id") REFERENCES "transaction"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tax_bracket" ADD CONSTRAINT "tax_bracket_tax_rule_set_id_fkey" FOREIGN KEY ("tax_rule_set_id") REFERENCES "tax_rule_set"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trigger_event" ADD CONSTRAINT "trigger_event_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent_run" ADD CONSTRAINT "agent_run_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent_run" ADD CONSTRAINT "agent_run_trigger_event_id_fkey" FOREIGN KEY ("trigger_event_id") REFERENCES "trigger_event"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent_run_attempt" ADD CONSTRAINT "agent_run_attempt_agent_run_id_fkey" FOREIGN KEY ("agent_run_id") REFERENCES "agent_run"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan" ADD CONSTRAINT "plan_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan" ADD CONSTRAINT "plan_agent_run_id_fkey" FOREIGN KEY ("agent_run_id") REFERENCES "agent_run"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan" ADD CONSTRAINT "plan_goal_config_id_fkey" FOREIGN KEY ("goal_config_id") REFERENCES "goal_config"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan" ADD CONSTRAINT "plan_tax_profile_id_fkey" FOREIGN KEY ("tax_profile_id") REFERENCES "tax_profile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "allocation_line" ADD CONSTRAINT "allocation_line_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "projection" ADD CONSTRAINT "projection_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_warning" ADD CONSTRAINT "plan_warning_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_classification" ADD CONSTRAINT "plan_input_classification_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_classification" ADD CONSTRAINT "plan_input_classification_classification_id_fkey" FOREIGN KEY ("classification_id") REFERENCES "transaction_classification"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_expected_income" ADD CONSTRAINT "plan_input_expected_income_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_expected_income" ADD CONSTRAINT "plan_input_expected_income_expected_income_version_id_fkey" FOREIGN KEY ("expected_income_version_id") REFERENCES "expected_income_version"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_recurring_expense" ADD CONSTRAINT "plan_input_recurring_expense_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_recurring_expense" ADD CONSTRAINT "plan_input_recurring_expense_recurring_expense_version_id_fkey" FOREIGN KEY ("recurring_expense_version_id") REFERENCES "recurring_expense_version"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_balance_snapshot" ADD CONSTRAINT "plan_input_balance_snapshot_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_balance_snapshot" ADD CONSTRAINT "plan_input_balance_snapshot_balance_snapshot_id_fkey" FOREIGN KEY ("balance_snapshot_id") REFERENCES "account_balance_snapshot"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_tax_rule_set" ADD CONSTRAINT "plan_input_tax_rule_set_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_input_tax_rule_set" ADD CONSTRAINT "plan_input_tax_rule_set_tax_rule_set_id_fkey" FOREIGN KEY ("tax_rule_set_id") REFERENCES "tax_rule_set"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in" ADD CONSTRAINT "check_in_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in" ADD CONSTRAINT "check_in_agent_run_id_fkey" FOREIGN KEY ("agent_run_id") REFERENCES "agent_run"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_in" ADD CONSTRAINT "check_in_resulting_classification_id_fkey" FOREIGN KEY ("resulting_classification_id") REFERENCES "transaction_classification"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendation_outcome" ADD CONSTRAINT "recommendation_outcome_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Partial unique indexes enforcing "one is_current=true row per parent" (docs/data-model.md
-- "How to read it": append-only versioning). These can't be expressed as a Prisma @@unique
-- (no WHERE clause in the schema DSL), so they're added here by hand.
CREATE UNIQUE INDEX "goal_config_one_current_per_user" ON "goal_config"("user_id") WHERE "is_current";

CREATE UNIQUE INDEX "tax_profile_one_current_per_user" ON "tax_profile"("user_id") WHERE "is_current";

CREATE UNIQUE INDEX "classification_one_current_per_txn" ON "transaction_classification"("transaction_id") WHERE "is_current";

CREATE UNIQUE INDEX "recurring_expense_one_current_per_expense" ON "recurring_expense_version"("recurring_expense_id") WHERE "is_current";

CREATE UNIQUE INDEX "expected_income_one_current_per_record" ON "expected_income_version"("expected_income_id") WHERE "is_current";
