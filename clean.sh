#!/bin/bash -e

echo "🔄 Cleaning up whoami resources..."

# Namespace
NAMESPACE=default

# Delete Ingress resource
echo "🧹 Deleting Ingress..."
microk8s kubectl delete ingress http-ingress-whoami --namespace $NAMESPACE --ignore-not-found

# Delete Certificate resource
echo "🧹 Deleting Certificate..."
microk8s kubectl delete certificate whoami-tls --namespace $NAMESPACE --ignore-not-found

# Optional: Delete TLS secret if it exists
echo "🧹 Deleting TLS secret..."
microk8s kubectl delete secret whoami-tls --namespace $NAMESPACE --ignore-not-found

# Delete CertificateRequests and Challenges
echo "🧹 Deleting CertificateRequests and Challenges..."
microk8s kubectl delete certificaterequests.cert-manager.io -l 'cert-manager.io/certificate-name=whoami-tls' --namespace $NAMESPACE --ignore-not-found
microk8s kubectl delete challenges.acme.cert-manager.io -l 'cert-manager.io/certificate-name=whoami-tls' --namespace $NAMESPACE --ignore-not-found
microk8s kubectl delete orders.acme.cert-manager.io -l 'cert-manager.io/certificate-name=whoami-tls' --namespace $NAMESPACE --ignore-not-found

# Delete Service resource
echo "🧹 Deleting Service..."
microk8s kubectl delete service whoami-service --namespace $NAMESPACE --ignore-not-found

# Delete Deployment resource
echo "🧹 Deleting Deployment..."
microk8s kubectl delete deployment whoami --namespace $NAMESPACE --ignore-not-found

echo "✅ Cleaned whoami test resources successfully."