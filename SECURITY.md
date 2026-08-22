# Security Policy

The **Dynamic Day & Night Wallpaper** project takes the security and integrity of user systems seriously. We appreciate
the responsible disclosure of security vulnerabilities by researchers and users.

---

## Supported Versions

Only the latest stable release branch receives security updates.

| Version |     Supported      | Status            |
|:--------|:------------------:|:------------------|
| 1.0.x   | :white_check_mark: | Current Stable    |
| < 1.0.0 |        :x:         | End of Life (EOL) |

---

## Reporting a Vulnerability

If you discover a security vulnerability or potential exploit in this project, please **do not open a public issue or
discussion**.

Instead, follow the responsible disclosure process below:

1. **Email us privately** at:  
   📧 **[Q300Zhomas@gmail.com](mailto:Q300Zhomas@gmail.com)**

2. **Include detailed information**:
    - A clear description of the vulnerability and its potential impact.
    - Step-by-step instructions or a minimal Proof of Concept (PoC) to reproduce the issue.
    - Affected versions, OS, KDE Plasma version, and environment details.
    - Any suggested mitigations or patches if available.

---

## Response Process & SLA

When a security vulnerability report is received:

1. **Acknowledgment**: We will acknowledge receipt of your report within **48 hours**.
2. **Assessment**: The maintainer will investigate the issue, determine its severity, and establish a remediation plan.
3. **Patch & Testing**: A fix will be developed in a private branch and validated across supported KDE Plasma 6
   environments.
4. **Release & Advisory**: A patched version will be released, accompanied by a public security advisory and release
   notes crediting the reporter (unless anonymity is requested).
5. **Coordinated Disclosure**: We aim to resolve and publish fixes within **30 days** of receiving a valid report,
   unless otherwise coordinated.

---

## Security Architecture & Best Practices

As a native KDE Plasma 6 wallpaper plugin (`Plasma/Wallpaper` KPackage):

- **No Remote Network Access**: The plugin operates entirely offline. Solar ephemeris calculations are performed locally
  via mathematical models without remote API queries or telemetry.
- **Local File Handling**: Image selection paths and KConfigXT configurations are restricted to local user files and
  validated against path traversal.
- **Declarative QML/JS**: The codebase relies strictly on standard declarative QtQuick and Kirigami components without
  external binary extensions.
