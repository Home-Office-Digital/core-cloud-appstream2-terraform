---
name: terraform-appstream2-maintenance
description: 'Maintain this Terraform repository for AWS AppStream 2.0 and security groups. Use when updating modules, variables, outputs, docs, or validating consistency across module files.'
argument-hint: 'Describe the module change, files to update, and acceptance criteria.'
user-invocable: true
---

# Terraform AppStream2 Maintenance

## When to Use
- Update AppStream 2.0 module behavior in `modules/appstream2/`
- Change security group module behavior in `modules/security-groups/`
- Add or modify variables, outputs, or defaults
- Keep Terraform code and module READMEs aligned
- Review change impact across module entrypoints and docs

## Procedure
1. Identify the target module and impacted files:
   - `main.tf`
   - `variables.tf`
   - `outputs.tf` (if present)
   - `README.md`
2. Apply minimal, consistent Terraform changes:
   - Preserve existing input/output names unless a rename is required
   - Keep variable descriptions and types explicit
   - Avoid changing unrelated resources
3. Ensure interface consistency:
   - New inputs are documented in the module README
   - New outputs are documented and described
   - Defaults and required fields are clear
4. Validate repository quality checks when available:
   - Run `terraform fmt -recursive`
   - Run `terraform validate` in relevant module contexts
5. Summarize changes clearly:
   - Files changed and why
   - Breaking changes, if any
   - Follow-up steps for callers of the modules

## Change Checklist
- Inputs updated in both Terraform and README
- Outputs updated in both Terraform and README
- No unintended resource name or behavior drift
- Formatting and validation completed
