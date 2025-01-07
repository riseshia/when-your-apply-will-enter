const loadData = async () => {
  try {
    const response = await fetch('./data.json');

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    window.appData = await response.json();
    return window.appData;
  } catch (error) {
    console.error('Failed to load data.json:', error);
  }
};

const renderAppliedTrend = (data) => {
  const ctx = document.getElementById('appliedTrend');

  const labels = data.map((d) => d.month);
  const oldDataset = data.map((d) => d.old_applied);
  const newDataset = data.map((d) => d.new_applied);

  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: '受理(旧受)',
        data: oldDataset,
        borderWidth: 1
      }, {
        label: '受理(新受)',
        data: newDataset,
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        x: {
          stacked: true
        },
        y: {
          stacked: true,
          beginAtZero: true
        }
      }
    }
  });
};

const renderCompletedTrend = (data) => {
  const ctx = document.getElementById('completedTrend');

  const labels = data.map((d) => d.month);
  const acceptedDataset = data.map((d) => d.accepted);
  const declinedDataset = data.map((d) => d.declined);
  const otherDataset = data.map((d) => d.other);

  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: '許可',
        data: acceptedDataset,
        borderWidth: 1
      }, {
        label: '却下',
        data: declinedDataset,
        borderWidth: 1
      }, {
        label: 'その他',
        data: otherDataset,
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        x: {
          stacked: true
        },
        y: {
          stacked: true,
          beginAtZero: true
        }
      }
    }
  });
}

const renderAppliedForcastTrend = (data) => {
  const ctx = document.getElementById('appliedForcastTrend');

  const xlabels = data.map((d) => d.month);
  const labels = ['過去分'].concat(data.map((d) => d.month));
  const processedNumPerMonth = [0].concat(data.map((d) => d.accepted + d.declined));
  const appliedPerMonth = [data[0].old_applied].concat(data.map((d) => d.new_applied));
  const pendingAppliedPerMonth = [0].concat(data.map((d) => d.old_applied));

  const labelNum = labels.length;
  const datasets = [];

  for(let i = 0; i < labelNum; i++) {
    const label = labels[i];

    let pendingApplied = pendingAppliedPerMonth[i];
    let applied = appliedPerMonth[i];
    let data = [];

    for(let targetMonth = 1; targetMonth < i + 1; targetMonth++) {
      data.push(0);
    }

    for(let targetMonth = i + 1; targetMonth < labelNum; targetMonth++) {
      const targetMonthProcessed = processedNumPerMonth[targetMonth];

      if (applied === 0) {
        data.push(0);
        continue;
      }

      if (pendingApplied > targetMonthProcessed) {
        data.push(applied);
        pendingApplied -= targetMonthProcessed;
      } else if (pendingApplied < targetMonthProcessed) {
        const rem = targetMonthProcessed - pendingApplied;
        pendingApplied = 0;

        if (rem > applied) {
          applied = 0;
          data.push(0);
        } else {
          applied -= rem;
          data.push(applied);
        }
      }
    }

    datasets.push({
      label: label,
      data: data,
      borderWidth: 1
    });
  }


  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: xlabels,
      datasets: datasets,
    },
    options: {
      scales: {
        x: {
          stacked: true
        },
        y: {
          stacked: true,
          beginAtZero: true
        }
      }
    }
  });
}

const renderAppliedProcessedTrend = (data) => {
  const ctx = document.getElementById('appliedProcessedTrend');

  const labels = data.map((d) => d.month);
  const newAppliedDataset = data.map((d) => d.new_applied);
  const processedDataset = data.map((d) => d.accepted + d.declined);

  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: '処理',
        data: processedDataset,
        borderWidth: 1
      }, {
        label: '受理',
        data: newAppliedDataset,
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        y: {
          beginAtZero: true
        }
      }
    }
  });
}

// data.json
// [
//   {
//     "month": "2020年11月",
//     "old_applied": 18910,
//     "new_applied": 2421,
//     "completed": 3279,
//     "accepted": 1526,
//     "declined": 1669,
//     "other": 84
//   },
// ]
const renderGraph = (data) => {
  renderAppliedProcessedTrend(data);
  renderAppliedTrend(data);
  renderCompletedTrend(data);
  renderAppliedForcastTrend(data);
}

const guessIfAppliedNow = (data) => {
  const last3Months = data.slice(-3);
  const avgCompletedNum = last3Months.reduce((acc, d) => acc + d.completed, 0) / 3;
  const lastApplied = last3Months[2].new_applied + last3Months[2].old_applied;

  const howManyMonth = Math.ceil(lastApplied / avgCompletedNum);

  const targetDate = new Date();
  targetDate.setMonth(targetDate.getMonth() + howManyMonth);

  const targetMonth = targetDate.toISOString().split('T')[0].split('-').slice(0, 2).join('年') + '月';

  const ifAppliedNowEl = document.getElementById('if-applied-now');
  ifAppliedNowEl.textContent = targetMonth;
}

window.onload = async () => {
  const data = await loadData();
  renderGraph(data);
  guessIfAppliedNow(data);
};
