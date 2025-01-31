apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: ${ecr_url}  # Este es el marcador de posición para la imagen de ECR
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              cpu: "200m"
              memory: "512Mi"
      imagePullSecrets:
        - name: ecr-secret  # Nombre del secreto para ECR
