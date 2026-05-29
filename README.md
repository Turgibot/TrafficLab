# SmartTransportation Lab - TrafficLab

A comprehensive traffic simulation and ETA prediction system that combines SUMO traffic simulation with advanced machine learning models for accurate travel time estimation.

![TrafficLab Simulation Interface](frontend/public/images/sim.png)

## 🚀 Overview

The SmartTransportation Lab at Ruppin Academic Center develops cutting-edge solutions for intelligent transportation systems. This project provides a complete platform for:

- **Real-time traffic simulation** using SUMO (Simulation of Urban Mobility)
- **Advanced ETA prediction** using Graph Neural Networks and Mixture-of-Experts models
- **Interactive web interface** for monitoring and analyzing traffic patterns
- **Comprehensive analytics** with performance metrics and visualization tools

## 🏛️ Research Team

- **Nadav Voloch** - Principal Investigator (Network Analysis & Smart City Applications)
- **Guy Tordjman** - Research Scientist (ETA Models & Data Analysis)
- **Maor Meir Hajaj** - Research Scientist (SUMO Integration & ETA Models)
- **Matan Shemesh** - Research Scientist (Algorithm Development & Testing)

## 📚 Recent Publications

- **Dynamic Route-Aware Graph Neural Networks for Accurate ETA Prediction** (I3E 2025) - Guy Tordjman, Nadav Voloch
- **Finding the fastest navigation route by real-time future traffic estimations** (COMCAS 2021) - Nadav Voloch, Noa Voloch-Bloch
- **Estimating accurate traffic time by smart simulative route predictions** (I3E 2025) - Nadav Voloch, Neev Penkar, Guy Tordjman

## 🛠️ Technology Stack

### Backend
- **FastAPI** - Modern Python web framework
- **SUMO** - Traffic simulation engine
- **PyTorch** - Deep learning framework
- **PyTorch Geometric** - Graph neural networks
- **PostgreSQL** - Database for journey tracking
- **SQLAlchemy** - ORM for database operations

### Frontend
- **Vue.js 3** - Progressive JavaScript framework
- **Tailwind CSS** - Utility-first CSS framework
- **Vite** - Fast build tool and development server

### Machine Learning
- **Graph Neural Networks** - For traffic network modeling
- **Mixture-of-Experts** - For specialized prediction models
- **Temporal modeling** - For time-series traffic data

## 🚀 Quick Start

### Prerequisites

- **Docker (recommended):** Docker Engine and Docker Compose (v2: `docker compose`, or legacy `docker-compose`)
- **Manual setup:** Python 3.10+ (3.11 matches the backend container), Node.js 18+, PostgreSQL 15+, and SUMO (see below)

### Run everything with Docker Compose (recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ruppin-SmartTransportation/TrafficLab.git
   cd TrafficLab
   ```

2. **Start the stack**
   ```bash
   docker compose up --build
   ```
   If your install only provides the older CLI, use: `docker-compose up --build`

   This starts:
   - **Frontend (Vite):** http://localhost:3000
   - **Backend (FastAPI):** http://localhost:8000
   - **PostgreSQL:** `localhost:5432` (defaults in `docker-compose.yml`: database `trafficlab`, user `user`, password `password`)

3. **Open the app**
   - Homepage: http://localhost:3000
   - ETA / journey demo: http://localhost:3000/demo
   - SUMO simulation demo: http://localhost:3000/sim-demo

   The backend creates database tables on startup; you do not need to run `init_db.py` when using this compose file.

### Manual installation (backend + frontend on the host)

Use this when you run Node and Python locally. You still need PostgreSQL and SUMO on your machine (or only Postgres via Docker).

#### 1. PostgreSQL

The backend defaults to `postgresql://user:password@localhost:5432/trafficlab` (see `backend/models/database.py`). Create a database and role that match that URL, or set `DATABASE_URL` to your own connection string.

**Convenient option:** from the repo root, start only the database container, then use the default URL:

```bash
docker compose up -d db
```

Wait until the DB is healthy before starting the backend.

#### 2. Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements.txt -f https://data.pyg.org/whl/torch-2.1.0+cpu.html
```

CPU PyTorch keeps installs small; for GPU, install `torch` from [pytorch.org](https://pytorch.org/get-started/locally/) first, then install `requirements.txt` with the matching PyTorch Geometric wheel index if needed.

**SUMO** (required for simulation features):

```bash
# Ubuntu/Debian
sudo apt-get install sumo sumo-tools sumo-doc

# macOS
brew install sumo
```

Ensure `sumo` is on your `PATH`. If TraCI cannot find SUMO, set `SUMO_HOME` per the [SUMO documentation](https://eclipse.dev/sumo/).

**Initialize tables (optional):** tables are also created when the API starts, but you can run:

```bash
python init_db.py
```

**Run the API** (run from the `backend` directory so imports and asset paths resolve):

```bash
export DATABASE_URL=postgresql://user:password@localhost:5432/trafficlab   # adjust if needed
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### 3. Frontend

In a second terminal:

```bash
cd frontend
npm install
npm run dev
```

Vite serves the UI at **http://localhost:3000**. In development the client calls **http://localhost:8000** (see `frontend/src/services/api.js`). To use another API origin, set `VITE_API_BASE_URL`.

## 📖 Usage

### Interactive Demo

1. **Open a demo**
   - **Journey / ETA demo:** click "Try Live Demo" on the homepage, or open http://localhost:3000/demo
   - **SUMO simulation map:** http://localhost:3000/sim-demo

2. **Set Route Points**
   - Click on roads in the traffic network map to set start and destination points
   - The system will automatically calculate the optimal route

3. **Monitor Simulation**
   - Watch real-time traffic simulation
   - View current simulation time and active trips
   - Monitor prediction accuracy in real-time

4. **Analyze Results**
   - View recent journeys with prediction vs actual results
   - Access detailed analytics and performance metrics
   - Generate visualizations for different trip categories

### API Usage

The backend provides a RESTful API for integration with other systems:

#### Health Check
```bash
curl http://localhost:8000/health
```

#### Get Simulation Status
```bash
curl http://localhost:8000/api/simulation/status
```

#### Journey statistics (example)
```bash
curl http://localhost:8000/api/journeys/statistics
```

#### Vehicle prediction (replace `VEHICLE_ID` with an active vehicle id from the simulation)
```bash
curl http://localhost:8000/api/simulation/vehicles/VEHICLE_ID/prediction
```

## 📊 Features

### Real-time Traffic Simulation
- **SUMO Integration**: Full-featured traffic simulation
- **Dynamic Routing**: Intelligent path planning based on real-time conditions
- **Multi-modal Support**: Cars, pedestrians, and public transport

### Advanced ETA Prediction
- **Graph Neural Networks**: Model complex traffic network relationships
- **Mixture-of-Experts**: Specialized models for different traffic conditions
- **Temporal Modeling**: Capture time-dependent traffic patterns

### Comprehensive Analytics
- **Performance Metrics**: MAE, accuracy, and error analysis
- **Categorical Analysis**: Performance by trip duration and distance
- **Visualization Tools**: Interactive charts and plots
- **Real-time Monitoring**: Live simulation statistics

### Interactive Interface
- **Traffic Network Map**: Visual representation of the road network
- **Journey Tracking**: Detailed logs of completed trips
- **Performance Dashboard**: Real-time analytics and metrics
- **Responsive Design**: Works on desktop and mobile devices

## 🔬 Research Applications

This platform supports various research applications:

- **Traffic Flow Analysis**: Study traffic patterns and congestion
- **ETA Model Development**: Test and compare prediction algorithms
- **Route Optimization**: Develop intelligent routing strategies
- **Smart City Planning**: Analyze urban mobility patterns
- **Machine Learning Research**: Experiment with GNN architectures

## 📁 Project Structure

```
TrafficLab/
├── backend/                 # FastAPI backend
│   ├── models/             # ML models and database
│   ├── services/           # SUMO integration services
│   ├── sumo/              # SUMO configuration files
│   └── main.py            # FastAPI application
├── frontend/               # Vue.js frontend
│   ├── src/
│   │   ├── components/     # Vue components
│   │   └── services/       # API services
│   └── public/            # Static assets
├── docker-compose.yml      # Docker configuration
└── README.md              # This file
```

## 🧪 Development

### Running Tests
```bash
# Backend: install pytest if needed, then run from backend/
cd backend
pip install pytest
python -m pytest
```

### Code Quality
```bash
# Python (install dev tools as needed)
cd backend
black .
flake8 .
```

## 📈 Performance

The system achieves impressive performance metrics:

- **Mean Absolute Error (MAE)**: 46 seconds (82% improvement over baseline)
- **Prediction Accuracy**: Up to 100% for short trips
- **Real-time Processing**: Handles 1000+ concurrent vehicles
- **Simulation Scale**: Supports large urban networks

## 🤝 Contributing

We welcome contributions! Please see our [GitHub repository](https://github.com/Ruppin-SmartTransportation) for:

- **Code Contributions**: Submit pull requests
- **Bug Reports**: Open issues for problems
- **Feature Requests**: Suggest new functionality
- **Documentation**: Help improve our docs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏛️ Funding

This research is supported by the Israeli Ministry of Innovation, Science and Technology (Proposal no. 0007846) through grant number 34836.

## 📞 Contact

- **Email**: nadavv@ruppin.ac.il
- **Location**: Ruppin Academic Center, Israel
- **Phone**: +972 98-983-866
- **GitHub**: [Ruppin-SmartTransportation](https://github.com/Ruppin-SmartTransportation)

## 🙏 Acknowledgments

- **Eclipse SUMO** - Traffic simulation framework
- **PyTorch Team** - Deep learning framework
- **Vue.js Community** - Frontend framework
- **Open Source Contributors** - Various libraries and tools

---

**SmartTransportation Lab** - Advancing Traffic Simulation and ETA Prediction through AI

*© 2025 SmartTransportation Lab. All rights reserved.*