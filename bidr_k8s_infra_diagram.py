"""
BIDR Containerized Kubernetes Infrastructure Diagram
"""
from diagrams import Diagram, Cluster
from diagrams.azure.compute import AKS, ContainerInstances, ContainerRegistries
from diagrams.azure.network import (
    VirtualNetworks,
    PublicIpAddresses,
    LoadBalancers,
    ApplicationGateway,
)
from diagrams.azure.security import KeyVaults
from diagrams.azure.storage import StorageAccounts

from diagrams.azure.web import AppServices
from diagrams.azure.devops import Devops, ApplicationInsights
from diagrams.azure.database import SQLDatabases
from diagrams.azure.general import Resource
from diagrams.onprem.inmemory import Redis

with Diagram(
    "BIDR Containerized Kubernetes Infrastructure",
    show=False,
    graph_attr={
        "pad": "1.0",
        "nodesep": "1.0",
        "ranksep": "1.2",
        "splines": "ortho"
    },
    node_attr={
        "margin": "0.4",
        "fontsize": "12",
    }
):

    with Cluster("Resource Group: bidr-k8s"):

        # Networking
        with Cluster("Networking"):
            dns_zone = Resource("bidr.co.za (DNS zone, Global)")

            app_gw = ApplicationGateway("BIDR-k8s-appgateway (West US)")
            vnet_aks = VirtualNetworks("BIDR-k8s-vnet (VNet, West US)")
            lb_k8s = LoadBalancers("BIDR-k8s-lb (Load Balancer, West US)")
            pip_ingress = PublicIpAddresses("BIDR-k8s-ingress-ip (West US)")

            # Proxy/Edge network for ingress
            vnet_edge = VirtualNetworks("BIDR-edge-vnet (East US 2)")
            nsg_edge = Resource("BIDR-edge-nsg (NSG, East US 2)")
            pip_edge = PublicIpAddresses("BIDR-edge-ip (East US 2)")

            # Management network
            vnet_mgmt = VirtualNetworks("BIDR-mgmt-vnet (West US)")
            bastion = Resource("BIDR-mgmt-bastion (Bastion, West US)")
            pip_mgmt = PublicIpAddresses("BIDR-mgmt-ip (West US)")

        # Container Platform
        with Cluster("Kubernetes Platform"):
            aks_cluster = AKS("BIDR-aks-cluster (AKS, West US)")
            node_pool_system = Resource("system-nodepool (3 nodes, Standard_D4s_v3)")
            node_pool_workload = Resource("workload-nodepool (5 nodes, Standard_D8s_v3)")

            # Container registry
            acr = ContainerRegistries("BIDRcontainerregistry (ACR, West US)")

        # Workloads (Containerized Services)
        with Cluster("Containerized Services"):
            api_service = ContainerInstances("BIDR-api-service (Deployment)")
            web_service = ContainerInstances("BIDR-web-service (Deployment)")
            worker_service = ContainerInstances("BIDR-worker-service (Deployment)")
            proxy_service = ContainerInstances("BIDR-proxy-service (Deployment)")

            # Kubernetes ingress controller
            ingress_controller = Resource("nginx-ingress-controller (K8s)")
            cert_manager = Resource("cert-manager (K8s)")

        # Databases
        with Cluster("Databases"):
            psql_flexible = SQLDatabases("BIDR-k8s-psqlserver (PostgreSQL Flexible, West US)")

        # Storage
        with Cluster("Storage"):
            storage_persistent = StorageAccounts("BIDRk8sstorage (Storage, West US)")
            storage_backup = StorageAccounts("BIDRk8sbackup (Storage, East US)")

            # Persistent volumes
            pv_data = Resource("BIDR-data-pv (Persistent Volume)")
            pv_logs = Resource("BIDR-logs-pv (Persistent Volume)")

        # Caching
        with Cluster("Caching"):
            redis_cache = Redis("BIDR-k8s-redis (Redis, West US)")

        # Observability & Monitoring
        with Cluster("Observability & Monitoring"):
            ai_k8s = ApplicationInsights("BIDR-k8s-insights (West US)")
            ai_workloads = ApplicationInsights("BIDR-workload-insights (West US)")

            # Kubernetes monitoring
            prometheus = Resource("prometheus (K8s monitoring)")
            grafana = Resource("grafana (K8s dashboards)")

            failure_anomalies_k8s = Resource("Failure Anomalies - BIDR-k8s (Global)")

        # Security & Secrets
        key_vault = KeyVaults("BIDR-k8s-keyvault (West US)")
        secret_store = Resource("secret-store-csi-driver (K8s)")

        # CI/CD
        devops = Devops("Azure DevOps (K8s Pipeline)")

        # Network connections
        dns_zone >> pip_ingress
        pip_ingress >> app_gw
        app_gw >> lb_k8s
        lb_k8s >> vnet_aks

        pip_edge >> vnet_edge
        vnet_edge >> proxy_service

        pip_mgmt >> vnet_mgmt
        vnet_mgmt >> bastion

        # AKS cluster connections
        vnet_aks >> aks_cluster
        aks_cluster >> [node_pool_system, node_pool_workload]

        # Container registry
        acr >> [api_service, web_service, worker_service, proxy_service]

        # Ingress and load balancing
        lb_k8s >> ingress_controller
        ingress_controller >> [api_service, web_service]
        cert_manager >> ingress_controller

        # Service connections
        api_service >> psql_flexible
        api_service >> redis_cache
        web_service >> api_service
        worker_service >> [psql_flexible, redis_cache]

        # Storage connections
        [api_service, worker_service] >> storage_persistent
        storage_persistent >> [pv_data, pv_logs]
        storage_backup >> storage_persistent

        # Security connections
        key_vault >> secret_store
        secret_store >> [api_service, web_service, worker_service]

        # Monitoring connections
        aks_cluster >> [ai_k8s, prometheus]
        [api_service, web_service, worker_service] >> ai_workloads
        prometheus >> grafana
        ai_k8s >> failure_anomalies_k8s

        # CI/CD connections
        devops >> acr
        devops >> aks_cluster
        devops - [api_service, web_service, worker_service, psql_flexible]

print("Containerized Kubernetes infrastructure diagram generated for BIDR resources.")
