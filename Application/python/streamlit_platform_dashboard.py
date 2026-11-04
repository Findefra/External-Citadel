#!/usr/bin/env python3
"""
Streamlit dashboard for Image Builder + CodePipeline status
"""

import streamlit as st
import boto3
import pandas as pd

st.set_page_config(page_title="AWS Platform Dashboard", layout="wide")
st.title("CI/CD + Image Builder Overview")

ib = boto3.client("imagebuilder")
cp = boto3.client("codepipeline")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Image Builder Pipelines")
    pipelines = ib.list_image_pipelines().get("imagePipelineList", [])
    if pipelines:
        df = pd.DataFrame([{
            "Name": p["name"],
            "Status": p["status"],
            "Last Run": p.get("dateLastRun", "Never")
        } for p in pipelines])
        st.dataframe(df, use_container_width=True)
    else:
        st.info("No pipelines found")

with col2:
    st.subheader("Recent CodePipelines")
    pipes = cp.list_pipelines().get("pipelines", [])
    data = []
    for p in pipes[:10]:
        name = p["name"]
        try:
            execs = cp.list_pipeline_executions(pipelineName=name, maxResults=1)
            status = execs["pipelineExecutionSummaries"][0]["status"] if execs.get("pipelineExecutionSummaries") else "None"
        except Exception:
            status = "Error"
        data.append({"Pipeline": name, "Last Status": status})
    st.dataframe(pd.DataFrame(data), use_container_width=True)

st.subheader("Quick Actions")
if st.button("Refresh Data"):
    st.rerun()
