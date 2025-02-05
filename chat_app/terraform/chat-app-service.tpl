apiVersion: v1
kind: Service
metadata:
  name: chat-app-service
  namespace: default
spec:
  selector:
    app: chat-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer  