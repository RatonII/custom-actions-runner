# custom-actions-runner
This repo it is used to store different custom runners for github actions controller for kubernetes
### Install actions controller for kubernetes
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm upgrade --install --namespace actions-runner-system --create-namespace \
             --set=authSecret.github_token=<GITHUB_TOKEN> \
             --set=authSecret.create=true \
             --wait actions-runner-controller actions-runner-controller/actions-runner-controller