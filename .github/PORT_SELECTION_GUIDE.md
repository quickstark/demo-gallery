# Port Selection Guide - Demo Gallery

**Date**: 2025-10-22
**Selected Port**: **9090**
**Previous Port**: 8080 (conflicted)

## ✅ Why Port 9090?

**Port 9090** was chosen for the demo-gallery application because:

- ✅ **Not commonly used** - Avoids conflicts with standard services
- ✅ **Easy to remember** - Clean, repeating digits
- ✅ **Dashboard-friendly** - Often used for web UIs and monitoring interfaces
- ✅ **Safe range** - Well below ephemeral port range (32768+)
- ✅ **Available** - Not in use by common development tools

## 🚫 Ports We Avoided

### Common Ports (Likely In Use)

| Port | Service | Why Avoided |
|------|---------|-------------|
| 80 | HTTP | Standard web traffic, likely used by nginx/Apache |
| 443 | HTTPS | Secure web traffic, likely used |
| 8080 | HTTP Alt | Very common alternate HTTP, **was conflicting** |
| 8000 | Dev Servers | Python/Django/FastAPI default |
| 3000 | React Dev | Create React App, Next.js dev server |
| 5000 | Flask | Flask development server |
| 8888 | Jupyter | Jupyter Notebook default |
| 8081 | HTTP Alt | Common alternate, likely conflicting |

### Why Not Other Alternatives?

| Port | Reason Not Chosen |
|------|-------------------|
| 8082-8089 | Still in common HTTP alternate range |
| 3001-3999 | Often used by Node.js development servers |
| 5001-5999 | Common for microservices |
| 4000-4999 | GraphQL servers, development tools |

## 📋 Port 9090 Usage

### Where It's Configured

**1. deploy.yml** (Container port mapping):
```yaml
-p 9090:80 \
```
Maps host port 9090 → container port 80

**2. deploy.yml** (Port conflict check):
```bash
PORT_9090_CONTAINER=$(docker ps --filter "publish=9090" --format "{{.Names}}" | head -1)
```
Checks if any container is using port 9090

**3. deploy.yml** (Health checks):
```bash
curl -f http://localhost:9090/health
curl -f http://localhost:9090/
```
Verifies application is accessible

### Access URLs

**Local (on Ubuntu server)**:
```
http://localhost:9090
```

**External (from browser)**:
```
http://YOUR_SERVER_IP:9090
```

**Example**:
```
http://192.168.1.100:9090
http://myserver.example.com:9090
```

## 🔒 Firewall Considerations

**If you can't access from external browser**, open port 9090:

### Ubuntu UFW
```bash
# Allow port 9090
sudo ufw allow 9090/tcp

# Check status
sudo ufw status
```

### iptables
```bash
# Allow port 9090
sudo iptables -A INPUT -p tcp --dport 9090 -j ACCEPT

# Save rules
sudo netfilter-persistent save
```

### Cloud Provider Security Groups
- AWS EC2: Add inbound rule for TCP port 9090
- Azure: Add inbound security rule for port 9090
- GCP: Add firewall rule for tcp:9090

## 🧪 Verification

### Check Port is Free Before Deployment
```bash
# Check if anything is using port 9090
sudo lsof -i :9090

# Expected: No output (port is free)
```

### Check After Deployment
```bash
# Verify container is running on port 9090
docker ps | grep demo-gallery

# Expected output:
# demo-gallery   Up 2 minutes   0.0.0.0:9090->80/tcp

# Test locally
curl http://localhost:9090/

# Should return HTML content
```

### Test External Access
```bash
# From your local machine (not the server)
curl http://YOUR_SERVER_IP:9090/

# Or open in browser
```

## 🔄 Changing to Different Port (If Needed)

**If port 9090 conflicts in the future**, follow this process:

### 1. Choose Alternative Port

**Good alternatives**:
- **9091-9099** - Same range, easy increment
- **9000-9089** - General application range
- **10000-10999** - Less common range

**Pick one** that's not in use:
```bash
# Check if port is free
sudo lsof -i :YOUR_PORT
```

### 2. Update deploy.yml

Replace all occurrences of `9090` with your chosen port:

```bash
# Using sed (backup original first)
cp .github/workflows/deploy.yml .github/workflows/deploy.yml.backup
sed -i 's/9090/YOUR_PORT/g' .github/workflows/deploy.yml
```

Or manually edit these locations:
- Port mapping: `-p 9090:80`
- Port check: `publish=9090`
- Health checks: `localhost:9090`
- Info messages: `port 9090`

### 3. Commit and Deploy

```bash
git add .github/workflows/deploy.yml
git commit -m "chore: Change application port to YOUR_PORT"
git push origin main
```

### 4. Update Documentation

Update this guide and any other references to port 9090.

## 📊 Port Registry (Your Server)

**Keep track of which services use which ports**:

| Port | Service | Container/Process |
|------|---------|-------------------|
| 80 | ? | ? |
| 8080 | ? | ? |
| 9090 | **Demo Gallery** | demo-gallery container |

**To see all ports in use**:
```bash
# Docker containers
docker ps --format "table {{.Names}}\t{{.Ports}}"

# All processes
sudo netstat -tulpn | grep LISTEN

# Or with ss
sudo ss -tulpn | grep LISTEN
```

## 🎯 Best Practices

### Port Selection Strategy

1. **Check what's in use** first
   ```bash
   sudo lsof -i :PORT
   ```

2. **Choose from safe ranges**:
   - 9000-9999 (General applications)
   - 10000-19999 (User applications)
   - Avoid: 1-1023 (System ports, require root)
   - Avoid: Common dev tools (3000, 5000, 8080, etc.)

3. **Document your choice** (like this file!)

4. **Update firewall** if needed

5. **Test accessibility** before finalizing

### Port Management

- **Keep a registry** of ports used on your server
- **Use consistent ranges** for related services
- **Avoid port hopping** - stick with chosen ports
- **Document reasons** for port choices

## 🎉 Summary

**Current Configuration**:
- **Port**: 9090
- **Mapping**: Host 9090 → Container 80
- **Access**: `http://your-server:9090`
- **Reason**: Avoids conflicts with common services

**Benefits**:
- ✅ No conflicts with 80, 8080, or other common ports
- ✅ Easy to remember and recognize
- ✅ Dashboard/UI-appropriate port number
- ✅ Properly documented for future reference

**Next Steps**:
1. Deploy and verify application runs on port 9090
2. Open firewall if needed for external access
3. Update any external documentation with new port

---

**Last Updated**: 2025-10-22
**Application**: Demo Gallery React Application
**Port**: 9090
**Status**: ✅ Configured and Documented
