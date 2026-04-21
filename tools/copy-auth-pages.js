const fs = require("fs");
const path = require("path");

const projectRoot = path.resolve(__dirname, "..");
const sourceDir = path.join(projectRoot, "public", "auth");
const targetDir = path.join(projectRoot, "build", "web", "auth");
const buildDir = path.join(projectRoot, "build", "web");

if (!fs.existsSync(sourceDir)) {
  throw new Error("Source auth directory does not exist: public/auth");
}

if (!fs.existsSync(buildDir)) {
  throw new Error("Flutter web build output was not found. Run `flutter build web` first.");
}

copyDirectory(sourceDir, targetDir);
console.log("[auth-pages] Synced public/auth into build/web/auth");

function copyDirectory(source, destination) {
  fs.mkdirSync(destination, { recursive: true });

  for (const entry of fs.readdirSync(source, { withFileTypes: true })) {
    const sourcePath = path.join(source, entry.name);
    const destinationPath = path.join(destination, entry.name);

    if (entry.isDirectory()) {
      copyDirectory(sourcePath, destinationPath);
    } else {
      fs.copyFileSync(sourcePath, destinationPath);
    }
  }
}
