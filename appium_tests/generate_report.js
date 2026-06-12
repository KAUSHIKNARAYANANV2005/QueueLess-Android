const ExcelJS = require('exceljs');

/**
 * Generates a styled Excel report for QueueLess QA results
 * @param {Array} results Array of test result objects
 * @param {string} outputPath Target path to write the Excel file
 */
async function generateReport(results, outputPath) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'QueueLess QA Auto';
  workbook.lastModifiedBy = 'QueueLess QA Auto';
  workbook.created = new Date();
  workbook.modified = new Date();

  // Create Dashboard sheet
  const dashboard = workbook.addWorksheet('Summary', {
    views: [{ showGridLines: true }]
  });
  
  // Create Details sheet
  const details = workbook.addWorksheet('Test Execution Details', {
    views: [{ showGridLines: true }]
  });
  
  // Details Sheet Columns
  details.columns = [
    { header: 'Test Case ID', key: 'id', width: 15 },
    { header: 'Module', key: 'module', width: 22 },
    { header: 'Test Type', key: 'testType', width: 18 },
    { header: 'Scenario', key: 'scenario', width: 35 },
    { header: 'Steps', key: 'steps', width: 55 },
    { header: 'Expected Result', key: 'expectedResult', width: 55 },
    { header: 'Status', key: 'status', width: 14 },
    { header: 'Duration (ms)', key: 'duration', width: 16 },
    { header: 'Failure Reason / Remarks', key: 'remarks', width: 50 }
  ];
  
  // Format details header
  details.getRow(1).height = 28;
  details.getRow(1).eachCell((cell) => {
    cell.font = { name: 'Segoe UI', size: 11, bold: true, color: { argb: 'FFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1F4E78' } };
    cell.alignment = { vertical: 'middle', horizontal: 'left' };
  });

  // Calculate stats
  let total = results.length;
  let passed = results.filter(r => r.status === 'PASS').length;
  let failed = results.filter(r => r.status === 'FAIL').length;
  let passRate = total > 0 ? (passed / total) * 100 : 0;
  
  // Group by category
  const categories = ['Unit Testing', 'Functional Testing', 'UI/UX Testing', 'Validation Testing', 'Deployable Status'];
  const catStats = {};
  categories.forEach(cat => {
    const catTests = results.filter(r => r.testType === cat);
    catStats[cat] = {
      total: catTests.length,
      passed: catTests.filter(r => r.status === 'PASS').length,
      failed: catTests.filter(r => r.status === 'FAIL').length
    };
  });

  // Title block
  dashboard.mergeCells('A1:I2');
  const titleCell = dashboard.getCell('A1');
  titleCell.value = 'QueueLess Android Mobile E2E Testing Summary';
  titleCell.font = { name: 'Segoe UI', size: 16, bold: true, color: { argb: 'FFFFFF' } };
  titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1F4E78' } };
  titleCell.alignment = { vertical: 'middle', horizontal: 'center' };

  // Summary Metrics Table
  dashboard.getCell('A4').value = 'Test Execution Summary';
  dashboard.getCell('A4').font = { name: 'Segoe UI', size: 12, bold: true, color: { argb: '1F4E78' } };
  
  const headers = ['Metric', 'Value'];
  const metrics = [
    ['Total Test Cases Run', total],
    ['Passed Tests', passed],
    ['Failed Tests', failed],
    ['Overall Pass Rate', `${passRate.toFixed(1)}%`],
    ['Deployable Status', passRate === 100 ? 'READY (100% PASS)' : 'BLOCKERS DETECTED']
  ];
  
  let currRow = 5;
  // Write Metric Headers
  headers.forEach((h, i) => {
    const cell = dashboard.getCell(currRow, i + 1);
    cell.value = h;
    cell.font = { name: 'Segoe UI', size: 11, bold: true, color: { argb: 'FFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5597' } };
    cell.alignment = { horizontal: 'left', vertical: 'middle' };
  });
  dashboard.getRow(currRow).height = 20;
  currRow++;

  metrics.forEach((m) => {
    const cell1 = dashboard.getCell(currRow, 1);
    const cell2 = dashboard.getCell(currRow, 2);
    cell1.value = m[0];
    cell2.value = m[1];
    cell1.font = { name: 'Segoe UI', size: 10, bold: true };
    cell2.font = { name: 'Segoe UI', size: 10, bold: true };
    cell1.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F2F2F2' } };
    
    if (m[0] === 'Passed Tests') {
      cell2.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'E2EFDA' } };
      cell2.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: '375623' } };
    } else if (m[0] === 'Failed Tests') {
      cell2.fill = { type: 'pattern', pattern: 'solid', fgColor: m[1] > 0 ? 'FCE4D6' : 'E2EFDA' };
      cell2.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: m[1] > 0 ? 'C65911' : '375623' } };
    } else if (m[0] === 'Overall Pass Rate') {
      cell2.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2CC' } };
      cell2.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: '7F6000' } };
    } else if (m[0] === 'Deployable Status') {
      cell2.fill = { type: 'pattern', pattern: 'solid', fgColor: passRate === 100 ? 'E2EFDA' : 'FCE4D6' };
      cell2.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: passRate === 100 ? '375623' : 'C65911' } };
    } else {
      cell2.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F2F2F2' } };
    }
    dashboard.getRow(currRow).height = 18;
    currRow++;
  });

  // Category Breakdown Table
  dashboard.getCell('D4').value = 'Category Breakdown';
  dashboard.getCell('D4').font = { name: 'Segoe UI', size: 12, bold: true, color: { argb: '1F4E78' } };
  
  const catHeaders = ['Category', 'Total Run', 'Passed', 'Failed', 'Pass Rate'];
  let catRow = 5;
  catHeaders.forEach((h, i) => {
    const cell = dashboard.getCell(catRow, i + 4);
    cell.value = h;
    cell.font = { name: 'Segoe UI', size: 11, bold: true, color: { argb: 'FFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5597' } };
    cell.alignment = { horizontal: 'center', vertical: 'middle' };
  });
  dashboard.getRow(catRow).height = 20;
  catRow++;

  categories.forEach(cat => {
    const stats = catStats[cat];
    const cTotal = stats.total;
    const cPassed = stats.passed;
    const cFailed = stats.failed;
    const cRate = cTotal > 0 ? (cPassed / cTotal) * 100 : 0;

    const cells = [
      dashboard.getCell(catRow, 4),
      dashboard.getCell(catRow, 5),
      dashboard.getCell(catRow, 6),
      dashboard.getCell(catRow, 7),
      dashboard.getCell(catRow, 8)
    ];

    cells[0].value = cat;
    cells[1].value = cTotal;
    cells[2].value = cPassed;
    cells[3].value = cFailed;
    cells[4].value = `${cRate.toFixed(1)}%`;

    cells[0].alignment = { horizontal: 'left' };
    cells[1].alignment = { horizontal: 'center' };
    cells[2].alignment = { horizontal: 'center' };
    cells[3].alignment = { horizontal: 'center' };
    cells[4].alignment = { horizontal: 'center' };

    cells.forEach((cell, idx) => {
      cell.font = { name: 'Segoe UI', size: 10 };
      if (idx === 4) {
        cell.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: '7F6000' } };
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2CC' } };
      } else if (idx === 2) {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'E2EFDA' } };
        cell.font = { name: 'Segoe UI', size: 10, color: { argb: '375623' } };
      } else if (idx === 3) {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: cFailed > 0 ? 'FCE4D6' : 'E2EFDA' };
        cell.font = { name: 'Segoe UI', size: 10, color: cFailed > 0 ? 'C65911' : '375623' };
      } else {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F9F9F9' } };
      }
    });
    dashboard.getRow(catRow).height = 18;
    catRow++;
  });

  // Device Info Table
  dashboard.getCell('A13').value = 'Target Environment & Metadata';
  dashboard.getCell('A13').font = { name: 'Segoe UI', size: 12, bold: true, color: { argb: '1F4E78' } };
  
  const envInfo = [
    ['Test Date', new Date().toLocaleString()],
    ['Android Version', 'Android 13 (API 33)'],
    ['Device Name', 'V2037 (Physical Device)'],
    ['Execution Host', 'Localhost (Lively Test)'],
    ['QA Tools', 'Appium (v2.x) + UIAutomator2 + Flutter SDK']
  ];

  let envRow = 14;
  envInfo.forEach(item => {
    const c1 = dashboard.getCell(envRow, 1);
    const c2 = dashboard.getCell(envRow, 2);
    c1.value = item[0];
    c2.value = item[1];
    c1.font = { name: 'Segoe UI', size: 10, bold: true };
    c2.font = { name: 'Segoe UI', size: 10 };
    c1.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F2F2F2' } };
    c2.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FAFAFA' } };
    dashboard.getRow(envRow).height = 18;
    envRow++;
  });

  // Set widths for dashboard columns
  dashboard.getColumn(1).width = 25;
  dashboard.getColumn(2).width = 22;
  dashboard.getColumn(3).width = 5;
  dashboard.getColumn(4).width = 25;
  dashboard.getColumn(5).width = 12;
  dashboard.getColumn(6).width = 12;
  dashboard.getColumn(7).width = 12;
  dashboard.getColumn(8).width = 15;

  // Add details row by row
  results.forEach(testCase => {
    const row = details.addRow({
      id: testCase.id,
      module: testCase.module,
      testType: testCase.testType,
      scenario: testCase.scenario,
      steps: testCase.steps,
      expectedResult: testCase.expectedResult,
      status: testCase.status,
      duration: testCase.duration,
      remarks: testCase.remarks || ''
    });

    row.height = 20;
    row.eachCell((cell, colNumber) => {
      cell.font = { name: 'Segoe UI', size: 10 };
      cell.alignment = { vertical: 'middle', horizontal: 'left' };
      
      // Column-specific alignments
      if (colNumber === 1 || colNumber === 7 || colNumber === 8) {
        cell.alignment = { vertical: 'middle', horizontal: 'center' };
      }
      
      // Color coding for status
      if (colNumber === 7) {
        cell.font = { name: 'Segoe UI', size: 10, bold: true };
        if (testCase.status === 'PASS') {
          cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'E2EFDA' } };
          cell.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: '375623' } };
        } else {
          cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FCE4D6' } };
          cell.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: 'C65911' } };
        }
      }
    });
  });

  // 6. Create Separate Category Sheets dynamically
  const categoryMap = {
    'Unit Testing': 'Unit Testing',
    'Functional Testing': 'Functional Testing',
    'UI/UX Testing': 'UI-UX Testing',
    'Validation Testing': 'Validation Testing',
    'Deployable Status': 'Deployable Status'
  };

  Object.keys(categoryMap).forEach(categoryKey => {
    const sheetName = categoryMap[categoryKey];
    const catSheet = workbook.addWorksheet(sheetName, {
      views: [{ showGridLines: true }]
    });

    // Configure columns for category sheet (layout matches screenshot)
    catSheet.columns = [
      { header: 'Test Case ID', key: 'id', width: 15 },
      { header: 'Module', key: 'module', width: 22 },
      { header: 'Scenario', key: 'scenario', width: 35 },
      { header: 'Steps', key: 'steps', width: 55 },
      { header: 'Expected Result', key: 'expectedResult', width: 55 },
      { header: 'Status', key: 'status', width: 14 },
      { header: 'Duration (ms)', key: 'duration', width: 16 },
      { header: 'Failure Reason / Remarks', key: 'remarks', width: 50 }
    ];

    // Format header row
    catSheet.getRow(1).height = 28;
    catSheet.getRow(1).eachCell((cell) => {
      cell.font = { name: 'Segoe UI', size: 11, bold: true, color: { argb: 'FFFFFF' } };
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5597' } };
      cell.alignment = { vertical: 'middle', horizontal: 'left' };
    });

    // Populate category rows
    const catResults = results.filter(r => r.testType === categoryKey);
    catResults.forEach(testCase => {
      const row = catSheet.addRow({
        id: testCase.id,
        module: testCase.module,
        scenario: testCase.scenario,
        steps: testCase.steps,
        expectedResult: testCase.expectedResult,
        status: testCase.status,
        duration: testCase.duration,
        remarks: testCase.remarks || ''
      });

      row.height = 20;
      row.eachCell((cell, colNumber) => {
        cell.font = { name: 'Segoe UI', size: 10 };
        cell.alignment = { vertical: 'middle', horizontal: 'left' };
        
        if (colNumber === 1 || colNumber === 6 || colNumber === 7) {
          cell.alignment = { vertical: 'middle', horizontal: 'center' };
        }
        
        if (colNumber === 6) {
          cell.font = { name: 'Segoe UI', size: 10, bold: true };
          if (testCase.status === 'PASS') {
            cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'E2EFDA' } };
            cell.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: '375623' } };
          } else {
            cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FCE4D6' } };
            cell.font = { name: 'Segoe UI', size: 10, bold: true, color: { argb: 'C65911' } };
          }
        }
      });
    });
  });

  // Save workbook
  await workbook.xlsx.writeFile(outputPath);
  console.log(`Excel report successfully saved to ${outputPath}`);
}

module.exports = { generateReport };
