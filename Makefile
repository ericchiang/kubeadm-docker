K8S_VERSION ?= 1.7.1
K8S_REPO ?= kubernetes/kubernetes
GO_VERSION ?= 1.8.3
IMAGE_VERSION ?= 0
DOCKER_IMAGE ?= quay.io/ericchiang/kubeadm:v$(K8S_VERSION)_$(IMAGE_VERSION)

_output/bin/kubeadm _output/bin/kubectl: _build/kubernetes
	mkdir -p _output/bin
	docker run  \
		--cidfile=cid \
		-v $(PWD)/_build/kubernetes:/go/src/k8s.io/kubernetes \
		golang:$(GO_VERSION)-alpine \
		/bin/sh -c 'apk add --no-cache --update alpine-sdk && go install -v k8s.io/kubernetes/cmd/kubectl && go install -v k8s.io/kubernetes/cmd/kubeadm'
	./scripts/docker-cp cid /go/bin/kubeadm _output/bin/kubeadm
	./scripts/docker-cp cid /go/bin/kubectl _output/bin/kubectl
	./scripts/docker-rm cid
	rm cid

.PHONY: docker-image
docker-image: _output/bin/kubeadm _output/bin/kubectl
	docker build -t $(DOCKER_IMAGE) .
	docker run --rm $(DOCKER_IMAGE) kubeadm # sanity check the image works

_build/kubernetes:
	mkdir -p _build
	cd _build && wget https://github.com/$(K8S_REPO)/archive/v$(K8S_VERSION).zip
	cd _build && unzip v$(K8S_VERSION).zip
	mv _build/kubernetes-$(K8S_VERSION) _build/kubernetes

.PHONY: clean
clean:
	rm -rf _build
	rm -rf _output
