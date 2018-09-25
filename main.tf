provider "google" {
  credentials = "${var.credentials}"
  region      = "${var.region}"
  project     = "${var.project_id}"
}

module "dcos-infrastructure" {
  source  = "dcos-terraform/infrastructure/gcp"
  version = "~> 0.0"

  name_prefix               = "${var.name_prefix}"
  infra_disk_type           = "${var.infra_disk_type}"
  infra_disk_size           = "${var.infra_disk_size}"
  infra_machine_type        = "${var.infra_machine_type}"
  infra_ssh_user            = "${var.infra_ssh_user}"
  infra_dcos_instance_os    = "${var.infra_dcos_instance_os}"
  infra_public_ssh_key_path = "${var.ssh_public_key_file}"
  dcos_version              = "${var.dcos_version}"
  num_masters               = "${var.num_masters}"
  num_private_agents        = "${var.num_private_agents}"
  num_public_agents         = "${var.num_public_agents}"
  master_cidr_range         = "${var.master_cidr_range}"
  agent_cidr_range          = "${var.agent_cidr_range}"
  infra_ssh_user            = "${var.infra_ssh_user}"
  admin_ips                 = "${var.admin_ips}"
  tags                      = "${var.tags}"

  providers = {
    google = "google"
  }
}

module "dcos-core" {
  source  = "dcos-terraform/dcos-install-remote-exec/null"
  version = "~> 0.0"

  # bootstrap
  bootstrap_ip         = "${module.dcos-infrastructure.bootstrap.public_ip[0]}"
  bootstrap_private_ip = "${module.dcos-infrastructure.bootstrap.private_ip[0]}"
  bootstrap_os_user    = "${module.dcos-infrastructure.bootstrap.ssh_user}"
  bootstrap_prereq-id  = "${module.dcos-infrastructure.bootstrap.prereq_id}"

  # master
  master_ips         = ["${module.dcos-infrastructure.masters.public_ips}"]
  master_private_ips = ["${module.dcos-infrastructure.masters.private_ips}"]
  masters_os_user    = "${module.dcos-infrastructure.masters.ssh_user}"
  masters_prereq-id  = "${module.dcos-infrastructure.masters.prereq_id}"
  num_masters        = "${var.num_masters}"

  # private agent
  private_agent_ips        = ["${module.dcos-infrastructure.private_agents.public_ips}"]
  private_agents_os_user   = "${module.dcos-infrastructure.private_agents.ssh_user}"
  private_agents_prereq-id = "${module.dcos-infrastructure.private_agents.prereq_id}"
  num_private_agents       = "${var.num_private_agents}"

  # public agent
  public_agent_ips        = ["${module.dcos-infrastructure.public_agents.public_ips}"]
  public_agents_os_user   = "${module.dcos-infrastructure.public_agents.ssh_user}"
  public_agents_prereq-id = "${module.dcos-infrastructure.public_agents.prereq_id}"
  num_public_agents       = "${var.num_public_agents}"

  # DC/OS options
  dcos_install_mode         = "install"
  dcos_cluster_name         = "${var.dcos_cluster_name}"
  dcos_version              = "${var.dcos_version}"
  custom_dcos_download_path = "${var.custom_dcos_download_path}"

  dcos_ip_detect_public_contents    = "${file("${path.module}/scripts/ip-detect-public.sh")}"
  dcos_ip_detect_contents           = "${file("${path.module}/scripts/ip-detect.sh")}"
  dcos_fault_domain_detect_contents = "${file("${path.module}/scripts/fault-domain-detect.sh")}"

  dcos_variant                   = "${var.dcos_variant}"
  dcos_license_key_contents      = "${var.dcos_license_key_contents}"
  dcos_master_discovery          = "static"
  dcos_exhibitor_storage_backend = "static"
}
