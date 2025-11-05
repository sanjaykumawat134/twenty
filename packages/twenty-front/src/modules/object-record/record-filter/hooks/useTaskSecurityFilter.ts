import { currentWorkspaceMemberState } from '@/auth/states/currentWorkspaceMemberState';
import { CoreObjectNameSingular } from '@/object-metadata/types/CoreObjectNameSingular';
import { useMemo } from 'react';
import { useRecoilValue } from 'recoil';
import { type RecordGqlOperationFilter } from 'twenty-shared/types';
import { isDefined } from 'twenty-shared/utils';
import { useGetRolesQuery } from '~/generated-metadata/graphql';

// Hook to generate a security filter for non-admin users viewing tasks
// Non-admin users can only see tasks assigned to them
// Admin users can see all tasks
export const useTaskSecurityFilter = (
  objectNameSingular: string,
): RecordGqlOperationFilter => {
  const currentWorkspaceMember = useRecoilValue(currentWorkspaceMemberState);

  const { data, error } = useGetRolesQuery({
    fetchPolicy: 'network-only',
  });
  const securityFilter = useMemo(() => {
    // Only apply security filter for task object
    if (objectNameSingular !== CoreObjectNameSingular.Task) {
      return {};
    }

    const currentWorkspaceMemberId = currentWorkspaceMember?.id;
    if (!isDefined(currentWorkspaceMemberId)) {
      return {};
    }
    if (isDefined(error)) {
      // this failing query indicates that user is a non admin user which does not have permission to this roles api, not the way to do but for instance
      // unable to figureout weather user is member or admin user
      return {
        assigneeId: {
          in: [currentWorkspaceMemberId],
        },
      };
    }
    const roles = data?.getRoles;

    if (!isDefined(roles)) {
      return {};
    }
    const adminRole = roles.find(
      (role) => role.label.toLowerCase() === 'admin',
    ); // again check for admin (not the best way)
    // Check if current user is in Admin’s workspaceMembers list
    const isAdmin = adminRole?.workspaceMembers?.some(
      (member) => member.id === currentWorkspaceMember?.id,
    );
    // Admin users can see all tasks
    // Check user-level admin flag (canAccessFullAdminPanel)
    // Note: Role-level admin permissions (canReadAllObjectRecords) are handled by backend
    // if (currentUser?.canAccessFullAdminPanel === true) {
    //   return {};
    // }
    if (isAdmin == true) {
      return {};
    }

    // Filter tasks where assigneeId is in the array containing current workspace member ID
    // Using 'in' format to match the standard relation filter format
    return {
      assigneeId: {
        in: [currentWorkspaceMemberId],
      },
    } as RecordGqlOperationFilter;
  }, [objectNameSingular, currentWorkspaceMember?.id, error, data?.getRoles]);

  return securityFilter;
};
