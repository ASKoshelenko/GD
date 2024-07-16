
// Loop through user data to get all scenario names
let scenarioIds = [];
for (let i = 0; i < userData.length; i++) {
  let user = userData[i];
  for (let j = 0; j < user.scenarios.length; j++) {
    let scenario = user.scenarios[j];
    if (!scenarioIds.includes(scenario.name)) {
      scenarioIds.push(scenario.name);
    }
  }
}

function snakeToTitleCase(str) {
  let words = str.split("_");
  let capitalizedWords = words.map(
    (word) => word.charAt(0).toUpperCase() + word.slice(1)
  );
  return capitalizedWords.join(" ");
}

function snakeToCamel(str) {
  return str.replace(/[-_]+(\w)/g, (match, group) => group.toUpperCase());
}

// Generate Scenario_Column headers
let scenarioHeaders = "";
for (let i = 0; i < scenarioIds.length; i++) {
  let scenarioName = snakeToTitleCase(scenarioIds[i]);
  let scenarioId = snakeToCamel(scenarioIds[i]);
  scenarioHeaders += `<th data-field="${scenarioId}">${scenarioName}</th>`;
}

document.write(scenarioHeaders);
