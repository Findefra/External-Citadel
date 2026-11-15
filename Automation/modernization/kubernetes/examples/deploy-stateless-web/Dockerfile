# Example generic static/API container — replace with your runtime build.
FROM public.ecr.aws/docker/library/nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
# HEALTHCHECK is optional; prefer K8s probes
EXPOSE 80
USER nginx
