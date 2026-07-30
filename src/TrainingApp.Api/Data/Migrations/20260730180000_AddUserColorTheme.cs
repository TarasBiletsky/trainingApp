using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TrainingApp.Api.Data.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20260730180000_AddUserColorTheme")]
public partial class AddUserColorTheme : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(name: "ColorTheme", schema: "training", table: "Users", type: "text", nullable: false, defaultValue: "purple");
        migrationBuilder.AddCheckConstraint(name: "CK_Users_ColorTheme", schema: "training", table: "Users", sql: "\"ColorTheme\" IN ('purple', 'toxic', 'red')");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "ColorTheme", schema: "training", table: "Users");
    }
}
