# 📊 Camera Module Telemetry Events

This document defines the **Telemetry events** used to track interactions, states, and system notifications in the Camera module.  
It includes **global events** that apply across the entire camera flow and links to **per-screen documentation** where more specific events are described.  

---

## 🌍 Global Events
Global events are tracked independently and apply to all camera flows.  

### 🖥️ Screen View Tracking
| Event Name | Severity | Description | Metadata |
| ---------- | -------- | ----------- | -------- |
| **screen_view** | ![Info](https://img.shields.io/badge/Info-green) | User navigated to a specific screen/view in the Camera module. | **screenName** |

### 📐 Breadcrumbs
| Event Name | Severity | Description | Metadata | Source |
| ---------- | -------- | ----------- | -------- | ------ |
| **orientation_changed** | ![Info](https://img.shields.io/badge/Info-green) | Device orientation changed during camera usage. | **previousOrientation**, **newOrientation** | Sensors |

### 📖 Metadata Notes
- **screenName** → Identifier for the current screen (e.g., `"camera_capture"`, `"camera_recording"`, `"gallery_view"`, `"media_preview"`).  
- **previousOrientation** → The prior device orientation (`portrait`, `landscape_left`, `landscape_right`, `portrait_upside_down`).  
- **newOrientation** → The updated device orientation after the change.  

---

## 📑 Per-Screen Telemetry Documentation
Each screen or module within the Camera flow has its own telemetry specification.  

- 📸 **Capture Photo & Recording Video Events** → [Camera Telemetry Events](./camera/camera-module-telemetry-events.md)  
- 🖼️ **Gallery View Events** → [Gallery Telemetry Events](./gallery/camera-module-telemetry-events-gallery.md)  
- 📺 **Media Preview (Full Screen) Events** → [Media Preview Telemetry Events](./gallery-preview/camera-module-telemetry-events-gallery-preview.md)  
