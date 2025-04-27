import "../../vendor/chart.js"

const GapChart = {
  mounted() {
    this.chartInstance = null;
    this.renderChart();

    this.handleEvent("update_data", ({ gaps, drivers }) => {
      this.renderChart(gaps, drivers);
    });
  },

  renderChart() {
    // Parse the data from the data attributes
    const gapData = JSON.parse(this.el.dataset.gaps || "{}");
    const drivers = JSON.parse(this.el.dataset.drivers || "[]");
    const gapType = this.el.dataset.gapType || "total_gap"; // Get the gap type (lap_gap or total_gap)
    
    // Destroy existing chart if it exists
    if (this.chartInstance) {
      this.chartInstance.destroy();
    }
    
    // Ensure we have a canvas element
    let canvas = this.el.querySelector('canvas');
    if (!canvas) {
      // Create a canvas element if it doesn't exist
      canvas = document.createElement('canvas');
      // Clear the container and append the canvas
      this.el.innerHTML = '';
      this.el.appendChild(canvas);
    }
    
    // Prepare data for Chart.js
    const lapNumbers = Object.keys(gapData).map(Number).sort((a, b) => a - b);
    
    // Get driver names and team colors
    const driverInfo = drivers.map(driverId => ({
      id: driverId,
      name: formatDriverId(driverId)
    }));

    // Group drivers by team color
    const teamGroups = {};
    driverInfo.forEach(driver => {
      const teamColor = getDriverColor(driver.name);
      if (!teamGroups[teamColor]) {
        teamGroups[teamColor] = [];
      }
      teamGroups[teamColor].push(driver);
    });
    
    // Create datasets for each driver
    const datasets = driverInfo.map(driver => {
      const driverData = lapNumbers.map(lapNumber => {
        const lapData = gapData[lapNumber];
        const driverGap = lapData.find(d => d.driver_id === driver.id);
        // Use either lap_gap or total_gap based on the selected type
        return driverGap ? driverGap[gapType] : null;
      });
      
      const teamColor = getDriverColor(driver.name);
      const color = tailwindToHex(teamColor);

      // Check if this is the second driver on the team
      const isSecondDriver = teamGroups[teamColor].indexOf(driver) === 1;

      return {
        label: driver.name,
        data: driverData,
        borderColor: color,
        backgroundColor: color + '33', // Add transparency
        fill: false,
        tension: 0.1,
        borderDash: isSecondDriver ? [5, 5] : [] // Add dashed line for second driver
      };
    });
    
    // Create the chart
    this.chartInstance = new Chart(canvas, {
      type: 'line',
      data: {
        labels: lapNumbers.map(lap => `Lap ${lap}`),
        datasets: datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        elements: {
          point:{
              radius: 0
          }
        },
        scales: {
          y: {
            title: {
              display: true,
              text: gapType === 'lap_gap' ? 'Gap to Leader per Lap (seconds)' : 'Total Gap to Leader (seconds)'
            },
            min: -10,
            reverse: true
          },
          x: {
            title: {
              display: true,
              text: 'Lap Number'
            }
          }
        },
        plugins: {
          title: {
            display: true,
            text: gapType === 'lap_gap' ? 'F1 Gap to Leader Per Lap' : 'F1 Cumulative Gap to Leader Over Race'
          },
          legend: {
            position: 'top'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const label = context.dataset.label || '';
                const value = context.parsed.y;
                return `${label}: ${value.toFixed(3)}s`;
              }
            }
          }
        }
      }
    });
  },

  updated() {
    this.renderChart();
  }
};

// Get driver color from the team color lookup
function getDriverColor(driverName) {
  // Color lookup from prediction_live.ex
  const colorLookup = {
    "Hamilton": "red-600",
    "Leclerc": "red-600",
    "Max Verstappen": "blue-600",
    "Tsunoda": "blue-600",
    "Norris": "orange-500",
    "Piastri": "orange-500",
    "Russell": "teal-400",
    "Antonelli": "teal-400",
    "Gasly": "sky-600",
    "Doohan": "sky-600",
    "Alonso": "emerald-600",
    "Stroll": "emerald-600",
    "Hulkenberg": "green-400",
    "Bortoleto": "green-400",
    "Ocon": "gray-400",
    "Bearman": "gray-400",
    "Lawson": "blue-400",
    "Hadjar": "blue-400",
    "Albon": "sky-300",
    "Sainz": "sky-300"
  };
  
  return colorLookup[driverName] || "gray-500"; // Default to gray-500 if not found
}

// Convert Tailwind color codes to hex
function tailwindToHex(tailwindColor) {
  const colorMap = {
    "red-600": "#DC2626",
    "blue-600": "#2563EB",
    "orange-500": "#F97316",
    "teal-400": "#2DD4BF",
    "sky-600": "#0284C7",
    "emerald-600": "#059669",
    "green-400": "#4ADE80",
    "gray-400": "#9CA3AF",
    "blue-400": "#60A5FA",
    "sky-300": "#7DD3FC",
    "gray-500": "#6B7280" // Default fallback
  };
  
  return colorMap[tailwindColor] || "#6B7280"; // Default to gray-500 if not found
}

// Helper function to format driver IDs for display
function formatDriverId(driverId) {
  // Convert snake_case to Title Case
  return driverId
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

export default GapChart;
