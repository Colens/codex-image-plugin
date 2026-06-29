import { loadLocalConfig } from "../cobabaai-image-plugin/server/load-local-config.js";

loadLocalConfig();
process.stdout.write(process.env.COBABAAI_API_KEY ? "loaded" : "missing");
