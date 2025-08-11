// Simple Function Node for Validation
// Less complex than full validation code node

// Quick validation function
function quickValidate(intent) {
  // Basic checks
  if (!intent.type) return { valid: false, reason: "Missing intent type" };
  if (!intent.device_ip) return { valid: false, reason: "Missing device IP" };
  
  // VLAN checks
  if (intent.type === 'vlan') {
    if (!intent.vlan_id || intent.vlan_id < 1 || intent.vlan_id > 4094) {
      return { valid: false, reason: "Invalid VLAN ID" };
    }
  }
  
  return { valid: true, reason: "Validation passed" };
}

// Execute
const intent = $json.parsed_intent || $json.intent;
const result = quickValidate(intent);

return [{
  json: {
    validation_passed: result.valid,
    validation_message: result.reason,
    intent: intent,
    tfs_number: $('Set').all()[0]?.change_number
  }
}];
