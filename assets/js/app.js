// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Sortable from "../vendor/Sortable";
import "../vendor/chart.js"
import GapChart from "./hooks/gap_chart"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {
  GapChart
}

Hooks.CumulativePointsChart = {
  mounted() {
    const ctx = this.el.getContext('2d');
    const chartData = JSON.parse(this.el.dataset.chartData);

    // Create a chart
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: chartData.labels,
        datasets: chartData.datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
          },
          title: {
            display: true,
            text: 'Cumulative Points Over Season'
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Points'
            }
          },
          x: {
            title: {
              display: true,
              text: 'Events'
            }
          }
        }
      }
    });
  },

  updated() {
    // Update chart data when it changes
    const chartData = JSON.parse(this.el.dataset.chartData);
    this.chart.data.labels = chartData.labels;
    this.chart.data.datasets = chartData.datasets;
    this.chart.update();
  },

  destroyed() {
    // Clean up chart when element is removed
    if (this.chart) {
      this.chart.destroy();
    }
  }
}

Hooks.Countdown = {
  mounted() {
    this.timer = null;
    this.updateCountdown();

    // Update the countdown every second
    this.timer = setInterval(() => this.updateCountdown(), 1000);
  },

  updateCountdown() {
    const deadlineStr = this.el.getAttribute("data-deadline");
    const deadline = new Date(deadlineStr);
    const now = new Date();

    // Calculate the time difference in milliseconds
    const diff = deadline - now;

    // If the deadline has passed, clear the interval and update the UI
    if (diff <= 0) {
      clearInterval(this.timer);
      this.el.outerHTML = `
        <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 rounded shadow">
          <div class="flex items-center">
            <svg class="h-6 w-6 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span class="font-semibold">Deadline passed</span>
          </div>
        </div>
      `;
      return;
    }

    // Calculate days, hours, minutes, and seconds
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((diff % (1000 * 60)) / 1000);

    // Format the countdown string
    let countdownStr = "";
    if (days > 0) {
      countdownStr += `${days} day${days !== 1 ? 's' : ''} `;
    }
    countdownStr += `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    // Update the countdown display
    const countdownElement = this.el.querySelector(".countdown-value");
    if (countdownElement) {
      countdownElement.textContent = countdownStr;
    }
  },

  destroyed() {
    // Clear the interval when the element is removed from the DOM
    if (this.timer) {
      clearInterval(this.timer);
    }
  }
},

Hooks.Sortable = {
  mounted(){
    let sorter = new Sortable(this.el, {
      animation: 150,
      delay: 100,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      forceFallback: true,
      onEnd: e => {
        let params = {old: e.oldIndex, new: e.newIndex, ...e.item.dataset}
        this.pushEventTo(this.el, "reposition", params)
      }
    })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
