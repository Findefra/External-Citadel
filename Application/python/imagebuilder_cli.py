#!/usr/bin/env python3
"""
aws-imagebuilder-cli – Trigger and monitor EC2 Image Builder pipelines
"""

import boto3
import click
from rich.console import Console
from rich.table import Table

console = Console()
ib = boto3.client("imagebuilder")

@click.group()
def cli():
    """EC2 Image Builder helper for Windows & RHEL pipelines"""
    pass

@cli.command()
def list_pipelines():
    """List all Image Builder pipelines"""
    resp = ib.list_image_pipelines()
    table = Table(title="Image Builder Pipelines")
    table.add_column("Name")
    table.add_column("Status")
    table.add_column("Last Execution")
    table.add_column("ARN", overflow="fold")

    for p in resp.get("imagePipelineList", []):
        table.add_row(
            p["name"],
            p["status"],
            p.get("dateLastRun", "Never"),
            p["arn"]
        )
    console.print(table)

@cli.command()
@click.argument("pipeline_name")
def trigger(pipeline_name: str):
    """Start a pipeline execution by name"""
    pipelines = ib.list_image_pipelines()["imagePipelineList"]
    match = next((p for p in pipelines if p["name"] == pipeline_name), None)
    if not match:
        console.print(f"[red]Pipeline '{pipeline_name}' not found[/red]")
        return

    resp = ib.start_image_pipeline_execution(imagePipelineArn=match["arn"])
    console.print(f"[green]Started execution:[/green] {resp['imageBuildVersionArn']}")

@cli.command()
@click.argument("execution_arn")
def status(execution_arn: str):
    """Get status of a specific image build"""
    resp = ib.get_image(imageBuildVersionArn=execution_arn)
    state = resp["image"]["state"]["status"]
    console.print(f"Status: [bold]{state}[/bold]")

if __name__ == "__main__":
    cli()
