// Validation Code Node - JavaScript
// This replaces the IF node with more flexible validation logic

function validateNetworkIntent(data) {
  const errors = [];
  const warnings = [];
  
  // Get the parsed intent from previous node
  const intent = data.parsed_intent || data.intent || {};
  
  // Basic validation rules
  if (!intent.type) {
    errors.push("Intent type is required");
  }
  
  // VLAN specific validation
  if (intent.type === 'vlan') {
    if (!intent.vlan_id) {
      errors.push("VLAN ID is required");
    } else if (intent.vlan_id < 1 || intent.vlan_id > 4094) {
      errors.push("VLAN ID must be between 1 and 4094");
    }
    
    if (!intent.name) {
      errors.push("VLAN name is required");
    } else if (!/^[a-zA-Z0-9_-]{1,32}$/.test(intent.name)) {
      errors.push("VLAN name must be 1-32 characters, alphanumeric, underscore, or dash only");
    }
    
    // Warning for common VLAN IDs
    if ([1, 1002, 1003, 1004, 1005].includes(intent.vlan_id)) {
      warnings.push(`VLAN ${intent.vlan_id} is a default VLAN, consider using a different ID`);
    }
  }
  
  // Route specific validation  
  if (intent.type === 'route') {
    const ipRegex = /^(\d{1,3}\.){3}\d{1,3}$/;
    const cidrRegex = /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/;
    
    if (!intent.destination) {
      errors.push("Route destination is required");
    } else if (!cidrRegex.test(intent.destination)) {
      errors.push("Route destination must be in CIDR format (e.g., 192.168.1.0/24)");
    }
    
    if (!intent.next_hop) {
      errors.push("Next hop IP is required");
    } else if (!ipRegex.test(intent.next_hop)) {
      errors.push("Next hop must be a valid IP address");
    }
  }
  
  // Device validation
  if (!intent.device_ip) {
    errors.push("Device IP is required");
  } else if (!/^(\d{1,3}\.){3}\d{1,3}$/.test(intent.device_ip)) {
    errors.push("Device IP must be a valid IP address");
  }
  
  // User permissions validation (basic example)
  const userRole = $('Set').all()[0]?.user_role || 'user';
  if (intent.type === 'route' && userRole !== 'admin') {
    errors.push("Only administrators can modify routing tables");
  }
  
  // Maintenance window check
  const currentHour = new Date().getHours();
  if (currentHour >= 9 && currentHour <= 17 && intent.priority !== 'emergency') {
    warnings.push("Changes during business hours require extra approval");
  }
  
  // Return validation result
  const isValid = errors.length === 0;
  
  return [{
    json: {
      validation: {
        is_valid: isValid,
        status: isValid ? 'VALID' : 'INVALID',
        errors: errors,
        warnings: warnings,
        validated_at: new Date().toISOString()
      },
      original_intent: intent,
      tfs_number: $('Set').all()[0]?.change_number
    }
  }];
}

// Execute validation
try {
  const inputData = $input.all()[0].json;
  return validateNetworkIntent(inputData);
} catch (error) {
  return [{
    json: {
      validation: {
        is_valid: false,
        status: 'ERROR',
        errors: [`Validation error: ${error.message}`],
        warnings: []
      },
      original_intent: inputData,
      error_details: error.stack
    }
  }];
}
