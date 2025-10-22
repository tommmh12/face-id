using Face_ID.Data;
using Face_ID.Models;
using Face_ID.Models.DTOs;
using Face_ID.Utilities;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace Face_ID.Services;

public interface IEmployeeService
{
    // Department
    Task<List<DepartmentResponse>> GetAllDepartmentsAsync();

    // Employee Management
    Task<CreateEmployeeResponse> CreateEmployeeAsync(CreateEmployeeRequest request);
    Task<List<EmployeeResponse>> GetAllEmployeesAsync();
    Task<EmployeeResponse?> GetEmployeeByIdAsync(int id);
    Task<List<EmployeeResponse>> GetEmployeesByDepartmentAsync(int departmentId);

    // ✅ UPDATE & DELETE Operations
    Task<UpdateEmployeeResponse> UpdateEmployeeAsync(int id, UpdateEmployeeRequest request);
    Task<UpdateDepartmentResponse> UpdateEmployeeDepartmentAsync(int id, UpdateDepartmentRequest request);
    Task<DeleteEmployeeResponse> DeleteEmployeeAsync(int id, string reason, string updatedBy);
    Task<RestoreEmployeeResponse> RestoreEmployeeAsync(int id, string reason, string updatedBy);

    // Face Registration
    Task<RegisterEmployeeFaceResponse> RegisterEmployeeFaceAsync(RegisterEmployeeFaceRequest request);
    Task<RegisterEmployeeFaceResponse> ReRegisterEmployeeFaceAsync(RegisterEmployeeFaceRequest request);
    
    // Face duplication check
    Task<CheckFaceRegistrationResponse> CheckIfFaceAlreadyRegisteredAsync(CheckFaceRegistrationRequest request);

    // Face Verification & Check-in/Check-out
    Task<VerifyEmployeeFaceResponse> VerifyEmployeeFaceAsync(VerifyFaceRequest request);
    Task<VerifyEmployeeFaceResponse> CheckOutEmployeeFaceAsync(VerifyFaceRequest request);

    // ✅ NEW: Activity Status Management
    Task<UpdateActivityStatusResponse> UpdateEmployeeActivityStatusAsync(int employeeId, string status);
}