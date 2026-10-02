"""Signature rules for the request IDS (ported from my_api, tuned for a POS).

Severity adds up per request; a single rule below the block threshold (70)
is only logged. Private-network URLs are low severity because tenants
legitimately configure LAN printers such as http://192.168.1.50:9100.
"""
import re
from dataclasses import dataclass


@dataclass(frozen=True)
class Rule:
    rule_id: str
    category: str
    severity: int
    pattern: re.Pattern[str]
    target: str = "any"  # any | path | query | headers | body


def _r(rule_id: str, category: str, severity: int, pattern: str, target: str = "any") -> Rule:
    return Rule(rule_id, category, severity, re.compile(pattern), target)


RULES: list[Rule] = [
    # SQL injection
    _r("sqli_union_select", "sql_injection", 45, r"(?i)\bunion\b\s+(all\s+)?\bselect\b"),
    _r("sqli_tautology", "sql_injection", 40, r"(?i)('|\")\s*or\s*('|\")?1('|\")?\s*=\s*('|\")?1"),
    _r("sqli_comment", "sql_injection", 35, r"(?i)('|\")\s*(--|#|/\*)"),
    _r("sqli_sleep_benchmark", "sql_injection", 50, r"(?i)\b(pg_sleep|sleep|benchmark|waitfor\s+delay)\s*\("),
    _r("sqli_stacked", "sql_injection", 45, r"(?i);\s*(drop|truncate|alter|create)\s+(table|database|schema)\b"),
    _r("sqli_info_schema", "sql_injection", 40, r"(?i)\b(information_schema|pg_catalog|pg_shadow)\b"),
    # XSS
    _r("xss_script_tag", "xss", 40, r"(?i)<\s*script\b"),
    _r("xss_event_handler", "xss", 35, r"(?i)<[^>]+\bon(error|load|click|mouseover|focus|toggle)\s*="),
    _r("xss_javascript_uri", "xss", 35, r"(?i)javascript\s*:"),
    _r("xss_svg_iframe", "xss", 35, r"(?i)<\s*(svg|iframe|object|embed)\b"),
    # Command injection
    _r("cmdi_shell_chain", "command_injection", 45, r"(?i)(;|\|\||&&|\|)\s*(curl|wget|bash|sh|nc|powershell|cmd)\b"),
    _r("cmdi_subshell", "command_injection", 45, r"(`[^`]+`|\$\([^)]+\))"),
    # Path traversal
    _r("path_traversal_dotdot", "path_traversal", 40, r"(\.\./|\.\.\\|%2e%2e(%2f|/|%5c))"),
    _r("path_traversal_sensitive", "path_traversal", 50, r"(?i)(/etc/passwd|/etc/shadow|/proc/self/environ|\\windows\\system32\\)"),
    # XXE
    _r("xxe_doctype", "xxe", 55, r"(?is)<!DOCTYPE[^>]*>", "body"),
    _r("xxe_entity", "xxe", 55, r"(?is)<!ENTITY[^>]+SYSTEM", "body"),
    # SSRF
    _r("ssrf_metadata", "ssrf", 60, r"(?i)https?://(169\.254\.169\.254|metadata\.google\.internal|100\.100\.100\.200)"),
    _r("ssrf_loopback", "ssrf", 35, r"(?i)https?://(127\.\d+\.\d+\.\d+|localhost|0\.0\.0\.0|\[::1?\])"),
    _r("ssrf_private_network", "ssrf", 15,
       r"(?i)https?://(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})"),
    _r("ssrf_dangerous_scheme", "ssrf", 50, r"(?i)\b(file|gopher|dict|ldap)://"),
    # Template injection / backdoors
    _r("ssti_jinja", "template_injection", 40, r"\{\{\s*[^}]*(__class__|__mro__|__subclasses__|config|self)[^}]*\}\}"),
    _r("backdoor_eval_base64", "backdoor", 65, r"(?i)eval\s*\(\s*base64_decode\s*\("),
    _r("backdoor_system_exec", "backdoor", 45, r"(?i)\b(system|shell_exec|passthru|popen|os\.system)\s*\("),
    # Scanner / probe paths (never valid on this API)
    _r("probe_dotfiles", "path_probe", 70, r"(?i)/\.(env|git|svn|hg|DS_Store|aws|ssh)(/|$)", "path"),
    _r("probe_wordpress", "path_probe", 70, r"(?i)/(wp-admin|wp-login\.php|wp-content|xmlrpc\.php)", "path"),
    _r("probe_actuator", "path_probe", 70, r"(?i)/actuator(/|$)", "path"),
    _r("probe_php", "path_probe", 50, r"(?i)\.(php|asp|aspx|jsp|cgi)(/|$|\?)", "path"),
    _r("probe_phpmyadmin", "path_probe", 50, r"(?i)/(phpmyadmin|pma|adminer)(/|$)", "path"),
    _r("probe_debug_trace", "path_probe", 45, r"(?i)/(trace\.axd|elmah|server-status|cgi-bin)", "path"),
    # Known scanner user agents
    _r("scanner_user_agent", "scanner", 70,
       r"(?i)(sqlmap|nikto|nmap|masscan|acunetix|nessus|dirbuster|gobuster|wpscan|nuclei|zgrab)", "headers"),
]
