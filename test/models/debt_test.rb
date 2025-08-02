require "test_helper"

class DebtTest < ActiveSupport::TestCase
  def setup
    @debt = debts(:credit_card_debt)
  end

  test "should be valid" do
    assert @debt.valid?
  end

  test "should require title" do
    @debt.title = nil
    assert_not @debt.valid?
    assert_includes @debt.errors[:title], "can't be blank"
  end

  test "should require amount" do
    @debt.amount = nil
    assert_not @debt.valid?
    assert_includes @debt.errors[:amount], "can't be blank"
  end

  test "should require creditor" do
    @debt.creditor = nil
    assert_not @debt.valid?
    assert_includes @debt.errors[:creditor], "can't be blank"
  end

  test "should require due_date" do
    @debt.due_date = nil
    assert_not @debt.valid?
    assert_includes @debt.errors[:due_date], "can't be blank"
  end

  test "should require valid status" do
    @debt.status = "invalid_status"
    assert_not @debt.valid?
    assert_includes @debt.errors[:status], "is not included in the list"
  end

  test "should require valid debt_type" do
    @debt.debt_type = "invalid_type"
    assert_not @debt.valid?
    assert_includes @debt.errors[:debt_type], "is not included in the list"
  end

  test "should detect overdue debt" do
    overdue_debt = debts(:overdue_debt)
    assert overdue_debt.overdue?
  end

  test "should not be overdue if paid" do
    overdue_debt = debts(:overdue_debt)
    overdue_debt.status = "paid"
    assert_not overdue_debt.overdue?
  end

  test "should calculate days until due" do
    future_debt = debts(:personal_loan)
    assert future_debt.days_until_due > 0
  end

  test "should have negative days for overdue debt" do
    overdue_debt = debts(:overdue_debt)
    assert overdue_debt.days_until_due < 0
  end
end
