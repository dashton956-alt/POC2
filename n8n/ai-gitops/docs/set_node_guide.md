# n8n Set Node Usage Guide

## Finding the Set Node in n8n

1. **In the n8n workflow editor:**
   - Click the "+" button to add a new node
   - Search for "Set" in the node search box
   - Select "Set" from the results

2. **Alternative names to search for:**
   - "Set" (primary name)
   - "Edit Fields" 
   - "Data transformation"

## Set Node Configuration Example

```json
{
  "values": {
    "change_number": "={{$json['change_number']}}",
    "timestamp": "={{$now.toISO()}}",
    "user_id": "={{$json['headers']['x-user-id'] || 'system'}}",
    "request_source": "={{$json['headers']['user-agent'] || 'direct'}}",
    "workflow_id": "={{$executionId}}",
    "priority": "={{$json['priority'] || 'medium'}}",
    "environment": "={{$json['environment'] || 'production'}}"
  },
  "keepOnlySet": false
}
```

## How to Configure the Set Node

1. **Add the Set node after your TFS Generator**
2. **Click on the Set node to configure it**
3. **Add fields by clicking "Add Value"**
4. **For each field:**
   - **Name:** Enter the variable name (e.g., `change_number`)
   - **Value:** Enter the expression or value (e.g., `={{$json['change_number']}}`)

## Common Set Node Patterns

### Pattern 1: Store Previous Node Output
```
Name: change_number
Value: ={{$json['change_number']}}
```

### Pattern 2: Add Current Timestamp
```
Name: timestamp
Value: ={{$now.toISO()}}
```

### Pattern 3: Set Default Values
```
Name: priority
Value: ={{$json['priority'] || 'medium'}}
```

### Pattern 4: Get Execution ID
```
Name: workflow_id
Value: ={{$executionId}}
```

## Alternative: Use "Edit Fields" Node

If you can't find "Set", look for "Edit Fields" which does the same thing:
- Search for "Edit Fields"
- Functions identically to Set node
- Same configuration options

## Accessing Set Node Values Later

Once you've set values in a Set node, reference them in later nodes:

```javascript
// In Code nodes
const changeNumber = $('Set').all()[0].change_number;

// In HTTP Request nodes
{{$('Set').all()[0].change_number}}

// In expressions
={{$('Set').all()[0].timestamp}}
```

## Troubleshooting

1. **If Set node is missing:**
   - Update n8n to latest version
   - Try searching "Edit Fields" instead

2. **If values aren't saving:**
   - Check that "keepOnlySet" is set to false
   - Verify expressions use correct syntax: `={{expression}}`

3. **If can't reference values:**
   - Ensure Set node is named correctly
   - Use node name in references: `$('Set').all()[0].fieldName`
