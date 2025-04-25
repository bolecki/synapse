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
    
    // Generate a color for each driver
    const colors = generateColors(drivers.length);
    
    // Create datasets for each driver
    const datasets = drivers.map((driverId, index) => {
      const driverData = lapNumbers.map(lapNumber => {
        const lapData = gapData[lapNumber];
        const driverGap = lapData.find(d => d.driver_id === driverId);
        return driverGap ? driverGap.gap : null;
      });
      
      return {
        label: formatDriverId(driverId),
        data: driverData,
        borderColor: colors[index],
        backgroundColor: colors[index] + '33', // Add transparency
        fill: false,
        tension: 0.1
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
        scales: {
          y: {
            title: {
              display: true,
              text: 'Gap to Leader (seconds)'
            },
            beginAtZero: true
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
            text: 'F1 Gap to Leader Over Race'
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

// Helper function to generate colors
function generateColors(count) {
  const baseColors = [
    '#FF0000', // Red (Ferrari)
    '#0600EF', // Blue (Red Bull)
    '#00D2BE', // Teal (Mercedes)
    '#FF8700', // Orange (McLaren)
    '#0090FF', // Light Blue (Alpine)
    '#2B4562', // Navy (Aston Martin)
    '#FFFFFF', // White (AlphaTauri)
    '#C8C8C8', // Silver (Haas)
    '#900000', // Dark Red (Alfa Romeo)
    '#005AFF', // Royal Blue (Williams)
    '#FFC0CB', // Pink
    '#800080', // Purple
    '#008000', // Green
    '#FFD700', // Gold
    '#FFA500', // Orange
    '#A52A2A', // Brown
    '#00FFFF', // Cyan
    '#FF00FF', // Magenta
    '#000080', // Navy
    '#808080'  // Gray
  ];
  
  // If we need more colors than in our base set, generate them
  if (count > baseColors.length) {
    for (let i = baseColors.length; i < count; i++) {
      const hue = (i * 137.5) % 360; // Use golden ratio to spread colors
      baseColors.push(`hsl(${hue}, 70%, 50%)`);
    }
  }
  
  return baseColors.slice(0, count);
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
