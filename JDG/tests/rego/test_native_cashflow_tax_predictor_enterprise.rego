# NexusAI JDG — Native Rego Tests for: cashflow_tax_predictor_enterprise
# Source: cashflow_tax_predictor_enterprise.rego

package test_jdg_cashflow_predictor

import data.jdg.cashflow_predictor

# no_match fallback

test_positive_no_match {
    result := data.jdg.cashflow_predictor.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.cashflow.no_match"
}

test_negative_no_match {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.rule_id != "jdg.cashflow.no_match"
}

# CFP-1700
test_positive_tax_liability_forecast_90d {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.matched == true
    result.rule_id == "jdg.cashflow.tax_liability_forecast_90d"
}

test_negative_tax_liability_forecast_90d {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_gap_check": true}
    result.rule_id != "jdg.cashflow.tax_liability_forecast_90d"
}

# CFP-1710
test_positive_liquidity_gap_detection {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_gap_check": true}
    result.matched == true
    result.rule_id == "jdg.cashflow.liquidity_gap_detection"
}

test_negative_liquidity_gap_detection {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.rule_id != "jdg.cashflow.liquidity_gap_detection"
}

# CFP-1720
test_positive_tax_deadline_calendar {
    result := data.jdg.cashflow_predictor.decide with input as {"tax_calendar_requested": true}
    result.matched == true
    result.rule_id == "jdg.cashflow.tax_deadline_calendar"
}

test_negative_tax_deadline_calendar {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.rule_id != "jdg.cashflow.tax_deadline_calendar"
}

# CFP-1730
test_positive_seasonal_pattern_detection {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_seasonal_check": true}
    result.matched == true
    result.rule_id == "jdg.cashflow.seasonal_pattern_detection"
}

test_negative_seasonal_pattern_detection {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.rule_id != "jdg.cashflow.seasonal_pattern_detection"
}

# CFP-1740
test_positive_buffer_recommendation {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_buffer_check": true}
    result.matched == true
    result.rule_id == "jdg.cashflow.buffer_recommendation"
}

test_negative_buffer_recommendation {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.rule_id != "jdg.cashflow.buffer_recommendation"
}

# CFP-1745
test_positive_annual_settlement_forecast {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_annual_forecast": true}
    result.matched == true
    result.rule_id == "jdg.cashflow.annual_settlement_forecast"
}

test_negative_annual_settlement_forecast {
    result := data.jdg.cashflow_predictor.decide with input as {"cashflow_forecast_requested": true}
    result.rule_id != "jdg.cashflow.annual_settlement_forecast"
}

# Dispatcher priority: forecast wins when multiple requests are present.
test_dispatcher_priority_forecast_over_other_flags {
    result := data.jdg.cashflow_predictor.decide with input as {
        "cashflow_forecast_requested": true,
        "cashflow_gap_check": true,
        "tax_calendar_requested": true,
        "cashflow_seasonal_check": true,
        "cashflow_buffer_check": true,
        "cashflow_annual_forecast": true
    }
    result.rule_id == "jdg.cashflow.tax_liability_forecast_90d"
}
