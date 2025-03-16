#ifndef native_lib_hpp
#define native_lib_hpp

#include <string>
#include <cstdio>
#include <thread>
#include <unistd.h>
#include <dlfcn.h>

#include <CoreFoundation/CoreFoundation.h>
extern "C" {
CF_EXPORT void CFLog(int32_t level, CFStringRef format, ...);
}

static std::string log_file;
extern "C" {
extern void erl_start(int argc, char **argv);
}

void ensure_slash(std::string& str)
{
    if (!str.empty() && str[str.size()-1] != '/') {
        str.append("/");
    }
}

#define LOG_ERROR(fmt, ...) CFLog(3, CFSTR("[CPP][ERROR] " fmt), ##__VA_ARGS__)
#define LOG_INFO(fmt, ...) CFLog(5, CFSTR("[CPP][INFO] " fmt), ##__VA_ARGS__)

#define ERROR_RETURN(x) { LOG_ERROR(x); return x; }


const char* startErlang(std::string root_dir, std::string log_dir, const char *app_version, const char *erts_version, std::string node_name)
{
    std::string bin_dir = getenv("BINDIR");
    static std::string env_path = std::string("PATH=").append(getenv("PATH")).append(":").append(bin_dir);
    
    chdir(root_dir.c_str());
    putenv((char *)env_path.c_str());
    
    std::string config_path = root_dir + "releases/" + app_version + "/sys";
    std::string config_path_complete = config_path + ".config";
    
    static char node_identifier[256];
    
    LOG_INFO("node_name: %s", node_name.c_str());
    
    int result = snprintf(node_identifier, sizeof(node_identifier), "%s", node_name.c_str());

    if (result < 0 || result >= sizeof(node_identifier)) {
        // Handle error: buffer too small or encoding error
        //  (e.g., return an error code, log a message, etc.)
         return "error_creating_node_id";
    }
    
    LOG_INFO("node_identifier: %s", node_identifier);
    
    if (access(config_path_complete.c_str(), R_OK) == 0) {
        LOG_INFO("sys.config file EXISTS: %s", config_path_complete.c_str());
    } else {
        ERROR_RETURN("sys.config file NOT FOUND or NOT READABLE ");
    }
    
    std::string boot_path = root_dir + "releases/" + app_version + "/start";
    if (access((boot_path + ".boot").c_str(), R_OK) != 0) {
        ERROR_RETURN("boot_path NOT FOUND or NOT READABLE");
    }
    
    std::string lib_path = root_dir + "lib";
    if (access(lib_path.c_str(), R_OK) != 0) {
        ERROR_RETURN("lib_path NOT FOUND or NOT READABLE");
    }
    
    std::string home_dir = getenv("HOME") ? getenv("HOME") : root_dir + "home";
    
    /*const char *args[] = {
        "test_main", "-sbwt", "none", "-MIscs", "10",
        "--", "-root", root_dir.c_str(), "-progname", "erl",
        "--", "-home", home_dir.c_str(), "--",
        "-kernel", "shell_history", "enabled",
        "--", "-elixir", "ansi_enabled", "true",
        "-noshell", "-s", "elixir", "start_cli",
        "-mode", "interactive", "-config", config_path.c_str(),
        "-boot", boot_path.c_str(), "-bindir", bin_dir.c_str(),
        "-boot_var", "RELEASE_LIB", lib_path.c_str(),
        "--", "--", "-extra", "--no-halt",
    };*/
    
    
    // long name vs short name
    // "-sname", node_name.c_str()
    // "-name", node_name.c_str()
    const char *args[] = {
        "test_main", "-sbwt", "none", "-MIscs", "10",
        "--", "-root", root_dir.c_str(), "-progname", "erl",
        "--", "-home", home_dir.c_str(), "--",
        "-kernel", "shell_history", "enabled",
        "--", "-elixir", "ansi_enabled", "true",
        "-noshell", "-s", "elixir", "start_cli",
        "-mode", "interactive", "-config", config_path.c_str(),
        "-boot", boot_path.c_str(), "-bindir", bin_dir.c_str(),
        "-boot_var", "RELEASE_LIB", lib_path.c_str(),
        "--", "--", "-name", node_identifier,
        "-setcookie", "testlitest",
        "-kernel", "inet_dist_use_interface", "{192,168,1,193}",
        "-extra", "--no-halt",
    };
    
    LOG_INFO("Starting Erlang...");
    try {
        erl_start(sizeof(args) / sizeof(args[0]), (char **)args);
    } catch (const std::exception &e) {
        LOG_ERROR("Erlang failed to start: %s", e.what());
        return "error_erl_start_failed";
    } catch (...) {
        LOG_ERROR("Erlang failed due to an unknown error");
        return "error_unknown";
    }
    return "ok";
}

extern "C" {
const char* start_erlang(const char* root, const char* home, const char* node_name) {
    static std::string root_dir = root;
    static std::string log_dir = home;
    
    static std::string new_node_name = node_name;
    
    LOG_INFO("start_erlang node_name: %s", node_name);
    
    ensure_slash(root_dir);
    ensure_slash(log_dir);
    log_file = log_dir + "elixir.log";
    
    std::string boot_file = root_dir + "releases/start_erl.data";
    FILE *fp = fopen(boot_file.c_str(), "rb");
    LOG_INFO("Start_erl.data file path: %s", boot_file.c_str());
    if (!fp) ERROR_RETURN("Could not locate start_erl.data");
    
    static char line_buffer[128];
    size_t read = fread(line_buffer, 1, sizeof(line_buffer) - 1, fp);
    fclose(fp);
    line_buffer[read] = 0;
    
    char* erts_version = strtok(line_buffer, " ");
    if (!erts_version) ERROR_RETURN("Could not identify erts version in start_erl.data");
    
    char* app_version = strtok(0, " ");
    if (!app_version) ERROR_RETURN("Could not identify app version in start_erl.data");
    
    std::thread erlang([=] {
        return startErlang(root_dir, log_dir, app_version, erts_version, new_node_name);
    });
    erlang.detach();
    
    return "starting";
}
}

#endif
