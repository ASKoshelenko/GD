// Parse data
const studentTableData = userData.map((row) => {
  const rowData = { username: row.username };
  let scoreValue = 0;
  row.scenarios.forEach((scenario) => {
    const scenarioName = scenario.name.replace(/_/g, "");
    // rowData[`${scenarioName}`] = scenario.passed
    //   ? '<img src="images/yes.png" alt="Passed!" height="42" width="42">'
    //   : '<img src="images/no.png" alt="In Progress!" height="42" width="42">';
    if (scenario.passed === "pass") {
      rowData[`${scenarioName}`] =
        '<img src="images/yes.png" alt="Passed!" height="42" width="42">';
    } else if (scenario.passed === "inProgress") {
      rowData[`${scenarioName}`] =
        '<img src="images/inProgress.png" alt="In Progress!" height="42" width="42">';
    } else if (scenario.passed === "failed") {
      rowData[`${scenarioName}`] =
        '<img src="images/no.png" alt="Not Passed!" height="42" width="42">';
    } else {
      rowData[`${scenarioName}`] = "";
    }
    scoreValue += (scenario.passed === "pass") ? 100 / row.scenarios.length : 0;
    rowData["absoluteScore"] = scoreValue;
    let roundScoreValue = Math.round(scoreValue);
    rowData["score"] = `
    <div class="progress-wrapper">
      <div class="progress-bar bg-success h-100" role="progressbar" style="width: ${roundScoreValue}%;" aria-valuenow="${roundScoreValue}" aria-valuemin="0" aria-valuemax="100">
        <div class="progress-bar-wrapper">
          <div class="progress-text">
            <h5>${roundScoreValue}%</h5>
          </div>
        </div>
      </div>
    </div>
    `;
  });
  return rowData;
});

// Sort students by completed scenarios
sortedStudentTableData = studentTableData.sort(
  (a, b) => b.absoluteScore - a.absoluteScore
);

// User numbering
for (let i = 0; i < sortedStudentTableData.length; i++) {
  studentTableData[i].number = i + 1;
}

$(function () {
  $("#student").bootstrapTable({
    data: sortedStudentTableData,
  });
});
