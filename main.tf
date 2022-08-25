provider "google" {
  project = var.project 
}


# create vpc

resource "google_compute_network" "vpc_network" {
  #project                 = "test-vpc-355610" 
  #project                 = var.project 
  name                    = "test-vpc-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# create default firewall rules

resource "google_compute_firewall" "allow_icmp" {
  name    = "test-default-allow-icmp"
  network = google_compute_network.vpc_network.self_link
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
  priority  = "65534"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "test-default-allow-ssh"
  network = google_compute_network.vpc_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  priority  = "65534"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "test-default-allow-internal"
  network = google_compute_network.vpc_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["0-65534"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65534"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.128.0.0/9"]
  priority  = "65534"
}

# create outer subnet

resource "google_compute_subnetwork" "outer-public-subnet" {
  name          = "outer-public-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "europe-west4"
  network       = google_compute_network.vpc_network.id
}

# create inner subnet

resource "google_compute_subnetwork" "inner-private-subnet" {
  name          = "inner-private-subnetwork"
  ip_cidr_range = "192.168.0.0/24"
  region        = "europe-west4"
  network       = google_compute_network.vpc_network.id
}

# create vms ...

resource "google_compute_instance" "instance-1" {
  name         = "webserver"
  machine_type = "f1-micro"
  zone         = "europe-west4-c"
  tags         = ["webserver"]

  network_interface {
    network    = "test-vpc-network"
    subnetwork = "outer-public-subnetwork"
    }

  metadata = {
    enable-oslogin = "TRUE"
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
}

resource "google_compute_instance" "instance-2" {
  name         = "database"
  machine_type = "f1-micro"
  zone         = "europe-west4-c"
  tags         = ["database"]

  network_interface {
    network    = "test-vpc-network"
    subnetwork = "inner-private-subnetwork"
    }

  metadata = {
    enable-oslogin = "TRUE"
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
}
