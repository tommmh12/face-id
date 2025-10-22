/// Test script to demonstrate debug output
/// Run this file to see how the debug system works
void main() {
  print('=== DEBUG SYSTEM TEST ===');
  
  // This is just a demo to show debug output format
  // The actual debug will appear when you use the app and make API calls
  
  print('\n🔍 When you use the salary editing feature, you will see debug output like this:');
  
  print('''
┌─────────────────────────────────────────────────────────────────────────────
│ 🚀 API REQUEST
├─────────────────────────────────────────────────────────────────────────────
│ Endpoint: /api/payroll/rules/version
│ Payload:
│ {
│   "employeeId": 1,
│   "baseSalary": 15000000.0,
│   "effectiveDate": "2025-10-22T00:00:00.000Z",
│   "reason": "Tăng lương định kỳ",
│   "standardWorkingDays": 22,
│   "socialInsuranceRate": 8.0,
│   "healthInsuranceRate": 1.5,
│   "unemploymentInsuranceRate": 1.0,
│   "personalDeduction": 11000000.0,
│   "numberOfDependents": 0,
│   "dependentDeduction": 4400000.0,
│   "createdBy": "HR Admin"
│ }
└─────────────────────────────────────────────────────────────────────────────

┌─────────────────────────────────────────────────────────────────────────────
│ ❌ API RESPONSE
├─────────────────────────────────────────────────────────────────────────────
│ Endpoint: Response
│ Status: 400
│ Response Body:
│ {
│   "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
│   "title": "One or more validation errors occurred.",
│   "status": 400,
│   "errors": {
│     "Reason": [
│       "The Reason field is required."
│     ],
│     "BaseSalary": [
│       "The field BaseSalary must be between 0 and 999999999."
│     ]
│   }
│ }
└─────────────────────────────────────────────────────────────────────────────

┌─────────────────────────────────────────────────────────────────────────────
│ 🚨 VALIDATION ERRORS FROM SERVER
├─────────────────────────────────────────────────────────────────────────────
│ Field: "Reason"
│   → The Reason field is required.
│
│ Field: "BaseSalary"
│   → The field BaseSalary must be between 0 and 999999999.
│
└─────────────────────────────────────────────────────────────────────────────

💥 ERROR: [PAYROLL] CreatePayrollRuleVersion thất bại: One or more validation errors occurred.
  ''');

  print('\n📱 TO SEE ACTUAL DEBUG OUTPUT:');
  print('1. Run: flutter run');
  print('2. Navigate to employee detail screen');
  print('3. Click "Sửa lương" button');
  print('4. Fill in the form and submit');
  print('5. Check the debug console for detailed output');
  
  print('\n🔧 DEBUG CONTROLS:');
  print('- Debug mode is enabled in DebugHelper class');
  print('- To disable debug in production, set _isDebugMode = false');
  print('- All API requests/responses will be logged with full details');
}