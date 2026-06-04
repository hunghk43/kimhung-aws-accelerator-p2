#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export KUBECONFIG=/root/.kube/config

log() {
  echo "[bootstrap] $1"
}

wait_for_docker() {
  log "Waiting for Docker to be ready"
  until docker info >/dev/null 2>&1; do
    sleep 2
  done
}

install_packages() {
  log "Installing base packages"
  apt-get update -y
  apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release docker.io
}

install_kind() {
  log "Installing kind"
  curl -fsLo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
  chmod +x /usr/local/bin/kind
}

install_kubectl() {
  log "Installing kubectl"
  curl -fsLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -fsL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x /usr/local/bin/kubectl
}

start_docker() {
  log "Starting Docker"
  systemctl enable docker
  systemctl start docker
}

write_kind_config() {
  log "Writing kind config"
  cat <<'EOF' >/tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
EOF
}

write_app_manifest() {
  log "Writing app manifest"
  mkdir -p /opt/week8
  cat <<'EOF' >/opt/week8/app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="vi">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Xbrain — AWS Partner #1 Việt Nam</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
          min-height: 100vh;
          background: #0a0a1a;
          font-family: 'Segoe UI', sans-serif;
          overflow-x: hidden;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          color: #fff;
        }

        .stars {
          position: fixed;
          inset: 0;
          z-index: 0;
          pointer-events: none;
        }
        .star {
          position: absolute;
          border-radius: 50%;
          background: #fff;
          animation: twinkle var(--d, 3s) ease-in-out infinite alternate;
          opacity: 0.6;
        }
        @keyframes twinkle { from { opacity: 0.2; transform: scale(0.8); } to { opacity: 1; transform: scale(1.2); } }

        .scene {
          perspective: 900px;
          z-index: 1;
          margin: 40px 20px;
        }
        .card {
          width: 680px;
          max-width: 95vw;
          background: linear-gradient(135deg, rgba(255,255,255,.07) 0%, rgba(255,255,255,.02) 100%);
          border: 1px solid rgba(255,255,255,.15);
          border-radius: 24px;
          padding: 52px 48px 44px;
          backdrop-filter: blur(18px);
          box-shadow: 0 30px 80px rgba(0,0,0,.6), inset 0 1px 0 rgba(255,255,255,.12);
          transform-style: preserve-3d;
          animation: float 6s ease-in-out infinite;
          transition: transform .12s ease;
        }
        @keyframes float {
          0%,100% { transform: rotateX(4deg) rotateY(-4deg) translateY(0); }
          50%      { transform: rotateX(-4deg) rotateY(4deg) translateY(-14px); }
        }

        .aws-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          background: linear-gradient(90deg, #ff9900, #ffb84d);
          color: #0a0a1a;
          font-size: .72rem;
          font-weight: 700;
          letter-spacing: .08em;
          text-transform: uppercase;
          padding: 5px 14px;
          border-radius: 20px;
          margin-bottom: 28px;
          box-shadow: 0 4px 16px rgba(255,153,0,.45);
          transform: translateZ(20px);
        }
        .aws-badge svg { width: 16px; height: 16px; }

        .brand {
          transform: translateZ(30px);
          margin-bottom: 10px;
        }
        .brand h1 {
          font-size: 3.4rem;
          font-weight: 900;
          letter-spacing: -.02em;
          background: linear-gradient(135deg, #00d4ff 0%, #7b2ff7 50%, #ff6ec7 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          filter: drop-shadow(0 0 24px rgba(0,212,255,.4));
        }
        .brand p {
          font-size: 1.05rem;
          color: rgba(255,255,255,.6);
          margin-top: 4px;
          letter-spacing: .04em;
        }

        .divider {
          height: 1px;
          background: linear-gradient(90deg, transparent, rgba(0,212,255,.5), transparent);
          margin: 28px 0;
          transform: translateZ(10px);
        }

        .stats {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 16px;
          margin-bottom: 32px;
          transform: translateZ(25px);
        }
        .stat-box {
          background: rgba(255,255,255,.05);
          border: 1px solid rgba(255,255,255,.1);
          border-radius: 14px;
          padding: 18px 12px;
          text-align: center;
          transition: background .2s;
        }
        .stat-box:hover { background: rgba(0,212,255,.1); }
        .stat-num {
          font-size: 1.9rem;
          font-weight: 800;
          background: linear-gradient(135deg, #00d4ff, #7b2ff7);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }
        .stat-label { font-size: .75rem; color: rgba(255,255,255,.5); margin-top: 4px; letter-spacing: .06em; }

        .desc {
          font-size: .97rem;
          line-height: 1.75;
          color: rgba(255,255,255,.72);
          transform: translateZ(15px);
          margin-bottom: 32px;
        }

        .tags {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          transform: translateZ(20px);
          margin-bottom: 36px;
        }
        .tag {
          font-size: .75rem;
          font-weight: 600;
          padding: 5px 12px;
          border-radius: 20px;
          border: 1px solid;
          letter-spacing: .05em;
        }
        .tag.blue  { color: #00d4ff; border-color: rgba(0,212,255,.4); background: rgba(0,212,255,.08); }
        .tag.purple{ color: #b07af7; border-color: rgba(123,47,247,.4); background: rgba(123,47,247,.08); }
        .tag.orange{ color: #ff9900; border-color: rgba(255,153,0,.4);  background: rgba(255,153,0,.08); }
        .tag.green { color: #4ade80; border-color: rgba(74,222,128,.4);  background: rgba(74,222,128,.08); }

        .k8s-status {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          background: rgba(74,222,128,.1);
          border: 1px solid rgba(74,222,128,.3);
          border-radius: 20px;
          padding: 8px 18px;
          font-size: .82rem;
          color: #4ade80;
          font-weight: 600;
          transform: translateZ(20px);
        }
        .pulse {
          width: 8px; height: 8px;
          border-radius: 50%;
          background: #4ade80;
          animation: pulse 1.4s ease-in-out infinite;
        }
        @keyframes pulse {
          0%,100% { transform: scale(1); opacity: 1; }
          50%      { transform: scale(1.6); opacity: .4; }
        }

        .footer {
          z-index: 1;
          margin-top: 10px;
          font-size: .78rem;
          color: rgba(255,255,255,.3);
          letter-spacing: .06em;
        }
      </style>
    </head>
    <body>
      <div class="stars" id="stars"></div>

      <div class="scene">
        <div class="card" id="card">
          <div class="aws-badge">
            <svg viewBox="0 0 24 24" fill="currentColor"><path d="M7.17 8.8c0 .37.04.67.11.89.08.22.19.46.35.72.06.09.08.18.08.26 0 .11-.07.23-.21.34l-.7.47c-.1.06-.2.1-.29.1-.11 0-.22-.06-.33-.17a3.4 3.4 0 0 1-.4-.52 8.6 8.6 0 0 1-.34-.65c-.86.1-1.53.57-1.53 1.47 0 .84.66 1.41 1.87 1.41.42 0 .87-.05 1.34-.14l-.01.62c-.45.13-.97.2-1.55.2C3.9 13.6 3 12.76 3 11.37c0-1.23.9-2.07 2.27-2.07.27 0 .53.03.78.08l.11-.01c0-.06-.01-.12-.01-.18 0-.5.13-.9.39-1.2.25-.28.59-.42 1-.42.1 0 .2.01.3.03l-.67 1.2zm9.65 4.08-.61-1.96-.63 1.96h1.24zm1.02 3.28-.55-1.74h-1.74l-.55 1.74h-1.12l1.97-5.87h1.15l1.97 5.87h-1.13zm4.31-5.87V16h-.97v-5.51h.97zm0-2.07v.97h-.97v-.97h.97z"/></svg>
            AWS Premier Partner #1 Việt Nam
          </div>

          <div class="brand">
            <h1>Xbrain</h1>
            <p>Kiến tạo tương lai số — Powered by Cloud &amp; AI</p>
          </div>

          <div class="divider"></div>

          <div class="stats">
            <div class="stat-box">
              <div class="stat-num">10+</div>
              <div class="stat-label">Năm kinh nghiệm</div>
            </div>
            <div class="stat-box">
              <div class="stat-num">500+</div>
              <div class="stat-label">Khách hàng tin dùng</div>
            </div>
            <div class="stat-box">
              <div class="stat-num">99.9%</div>
              <div class="stat-label">SLA uptime</div>
            </div>
          </div>

          <p class="desc">
            Xbrain là đối tác AWS hàng đầu Việt Nam, chuyên cung cấp giải pháp
            Cloud Infrastructure, DevOps, Data &amp; AI. Chúng tôi giúp doanh nghiệp
            chuyển đổi số nhanh chóng, an toàn và tối ưu chi phí.
          </p>

          <div class="tags">
            <span class="tag blue">Kubernetes</span>
            <span class="tag purple">Terraform</span>
            <span class="tag orange">AWS EC2</span>
            <span class="tag orange">AWS ALB</span>
            <span class="tag green">Minikube</span>
            <span class="tag blue">Docker</span>
            <span class="tag purple">IaC</span>
            <span class="tag green">DevOps</span>
          </div>

          <div class="k8s-status">
            <div class="pulse"></div>
            Running on Kubernetes · Deployed via Terraform 1-Click
          </div>
        </div>
      </div>

      <p class="footer">© 2025 Xbrain Technology · xbrain.vn · K8s on AWS Demo</p>

      <script>
        const container = document.getElementById('stars');
        for (let i = 0; i < 120; i++) {
          const s = document.createElement('div');
          s.className = 'star';
          const size = Math.random() * 2.5 + .5;
          s.style.cssText = `
            width:${size}px; height:${size}px;
            top:${Math.random()*100}vh; left:${Math.random()*100}vw;
            --d:${(Math.random()*3+2).toFixed(1)}s;
            animation-delay:${(Math.random()*4).toFixed(1)}s
          `;
          container.appendChild(s);
        }

        const card = document.getElementById('card');
        document.addEventListener('mousemove', e => {
          const cx = window.innerWidth / 2, cy = window.innerHeight / 2;
          const rx = ((e.clientY - cy) / cy) * 8;
          const ry = ((e.clientX - cx) / cx) * -8;
          card.style.transform = `rotateX(${rx}deg) rotateY(${ry}deg)`;
        });
        document.addEventListener('mouseleave', () => {
          card.style.transform = '';
        });
      </script>
    </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: web-content
        configMap:
          name: web-content
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
EOF
}

create_cluster() {
  log "Creating kind cluster"
  kind create cluster --name lab --config /tmp/kind-config.yaml
}

sync_kubeconfig() {
  log "Sharing kubeconfig with session users"
  for home_dir in /home/ssm-user /home/ubuntu; do
    mkdir -p "$home_dir/.kube"
    cp /root/.kube/config "$home_dir/.kube/config"
    chmod 0644 "$home_dir/.kube/config"
  done
}

apply_manifest() {
  log "Applying Kubernetes manifest"
  kubectl apply -f /opt/week8/app.yaml
  kubectl rollout status deployment/web --timeout=180s
}

main() {
  install_packages
  start_docker
  wait_for_docker
  install_kind
  install_kubectl
  write_kind_config
  create_cluster
  sync_kubeconfig
  write_app_manifest
  apply_manifest
  log "Bootstrap complete"
}

main "$@"