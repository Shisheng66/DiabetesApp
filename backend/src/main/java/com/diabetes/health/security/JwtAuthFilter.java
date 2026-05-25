package com.diabetes.health.security;

import com.diabetes.health.entity.UserAccount;
import com.diabetes.health.repository.UserAccountRepository;
import com.diabetes.health.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final TokenBlacklistService tokenBlacklistService;
    private final UserAccountRepository userAccountRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        if (StringUtils.hasText(authHeader) && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtil.validate(token) && !tokenBlacklistService.isRevoked(token)) {
                Long userId = jwtUtil.getUserId(token);
                userAccountRepository.findById(userId)
                        .filter(account -> account.getStatus() == UserAccount.AccountStatus.NORMAL)
                        .ifPresent(account -> {
                            String role = account.getRole() == null ? "" : account.getRole().name();
                            CurrentUser user = new CurrentUser(account.getId(), account.getPhone(), role);
                            List<SimpleGrantedAuthority> authorities = StringUtils.hasText(role)
                                    ? List.of(new SimpleGrantedAuthority("ROLE_" + role.trim().toUpperCase()))
                                    : List.of();
                            UsernamePasswordAuthenticationToken auth =
                                    new UsernamePasswordAuthenticationToken(user, null, authorities);
                            SecurityContextHolder.getContext().setAuthentication(auth);
                        });
            }
        }
        filterChain.doFilter(request, response);
    }
}
