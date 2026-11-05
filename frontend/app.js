
const content = document.getElementById("page-content");
const pageTitle = document.getElementById("page-title");

const services = {
  users: {
    title: "Users Management",
    endpoint: "/users",
    health: "/health/user"
  },
  products: {
    title: "Products Management",
    endpoint: "/products",
    health: "/health/product"
  },
  orders: {
    title: "Orders Management",
    endpoint: "/orders",
    health: "/health/order"
  }
};

function getRows(data) {
  if (Array.isArray(data)) return data;

  if (data && typeof data === "object") {
    const array = Object.values(data).find(Array.isArray);
    if (array) return array;
    return [data];
  }

  return [];
}

async function getData(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error("Request failed: " + url);
  return response.json();
}

function createTable(rows) {
  if (!rows.length) return "<p>No records found.</p>";

  const columns = [...new Set(rows.flatMap(row => Object.keys(row)))];

  return `
    <div class="table-wrapper">
      <table class="data-table">
        <thead>
          <tr>${columns.map(col => `<th>${col}</th>`).join("")}</tr>
        </thead>
        <tbody>
          ${rows.map(row => `
            <tr>
              ${columns.map(col => `<td>${row[col] ?? "-"}</td>`).join("")}
            </tr>
          `).join("")}
        </tbody>
      </table>
    </div>
  `;
}

async function showDashboard() {
  pageTitle.textContent = "Dashboard";
  content.innerHTML = `
    <div class="welcome">
      <h2>Welcome to your Microservices Dashboard</h2>
      <p>Monitor and manage your application services from one place.</p>
    </div>
    <div class="stats-grid">
      <div class="stat-card"><h3>Users</h3><p id="user-count">...</p></div>
      <div class="stat-card"><h3>Products</h3><p id="product-count">...</p></div>
      <div class="stat-card"><h3>Orders</h3><p id="order-count">...</p></div>
    </div>
    <h2 class="section-heading">Service Health</h2>
    <div id="health-list" class="health-list">Checking services...</div>
  `;

  for (const [name, service] of Object.entries(services)) {
    try {
      const data = getRows(await getData(service.endpoint));
      document.getElementById(`${name.slice(0, -1)}-count`)?.textContent;
      const countId = {
        users: "user-count",
        products: "product-count",
        orders: "order-count"
      }[name];
      document.getElementById(countId).textContent = data.length;
    } catch {
      const countId = {
        users: "user-count",
        products: "product-count",
        orders: "order-count"
      }[name];
      document.getElementById(countId).textContent = "Unavailable";
    }
  }

  const healthList = document.getElementById("health-list");

  for (const [name, service] of Object.entries(services)) {
    let status = "Offline";

    try {
      await getData(service.health);
      status = "Healthy";
    } catch {
      status = "Unavailable";
    }

    healthList.innerHTML += `
      <div class="health-item">
        <span>${name.charAt(0).toUpperCase() + name.slice(1)} Service</span>
        <strong class="${status === "Healthy" ? "healthy" : "offline"}">${status}</strong>
      </div>
    `;
  }
}

async function showService(name) {
  const service = services[name];
  pageTitle.textContent = service.title;

  content.innerHTML = `
    <div class="page-card">
      <h2>${service.title}</h2>
      <p>Live data from the ${name} microservice.</p>
      <div id="service-data">Loading records...</div>
    </div>
  `;

  try {
    const data = getRows(await getData(service.endpoint));
    document.getElementById("service-data").innerHTML = createTable(data);
  } catch (error) {
    document.getElementById("service-data").innerHTML =
      `<p class="error-message">Unable to load ${name}. Check the service and API.</p>`;
  }
}

document.querySelectorAll(".nav-btn").forEach(button => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".nav-btn").forEach(btn => btn.classList.remove("active"));
    button.classList.add("active");

    const page = button.dataset.page;

    if (page === "dashboard") {
      showDashboard();
    } else {
      showService(page);
    }
  });
});

showDashboard();
