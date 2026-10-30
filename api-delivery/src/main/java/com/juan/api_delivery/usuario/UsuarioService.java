package com.juan.api_delivery.usuario;

import com.juan.api_delivery.auth.CredenciaisInvalidasException;
import com.juan.api_delivery.shared.validation.CpfValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;

import static com.juan.api_delivery.shared.exception.MensagensErro.EMAIL_JA_CADASTRADO;
import static com.juan.api_delivery.shared.exception.MensagensErro.USUARIO_JA_ATIVO;
import static com.juan.api_delivery.shared.exception.MensagensErro.USUARIO_NAO_ENCONTRADO;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository repository;

    public List<Usuario> listarTodos() {
        return repository.findByAtivoTrue();
    }

    /**
     * Usado pela tela de administração: retorna todos os usuários,
     * incluindo os inativos.
     */
    public List<Usuario> listarTodosAdmin() {
        return repository.findAll();
    }

    public Usuario buscarPorId(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new RuntimeException(USUARIO_NAO_ENCONTRADO));
    }

    public Usuario criar(UsuarioDTO dto) {
        String email = normalizarEmail(dto.getEmail());
        // Vale também para conta inativa: ela só volta pelo PATCH /usuarios/{id}/reativar
        // do admin, nunca por um novo cadastro que sobrescreveria os dados dela.
        if (repository.findByEmailIgnoreCase(email).isPresent()) {
            throw new IllegalArgumentException(EMAIL_JA_CADASTRADO);
        }
        Usuario usuario = Usuario.builder()
            .nome(dto.getNome())
            .cpf(CpfValidator.somenteDigitos(dto.getCpf()))
            .email(email)
            .senha(dto.getSenha())
            .telefone(dto.getTelefone())
            .dataCadastro(LocalDate.now())
            .perfil(PerfilUsuario.CLIENTE)
            .build();
        return repository.save(usuario);
    }

    public Usuario atualizar(Long id, UsuarioDTO dto) {
        Usuario usuario = buscarPorId(id);
        String email = normalizarEmail(dto.getEmail());
        repository.findByEmailIgnoreCase(email)
            .filter(u -> !u.getId().equals(id))
            .ifPresent(u -> { throw new IllegalArgumentException(EMAIL_JA_CADASTRADO); });
        usuario.setNome(dto.getNome());
        usuario.setCpf(CpfValidator.somenteDigitos(dto.getCpf()));
        usuario.setEmail(email);
        usuario.setSenha(dto.getSenha());
        usuario.setTelefone(dto.getTelefone());
        return repository.save(usuario);
    }

    /** Reativa um usuário excluído (inativo). Usado pela tela de administração. */
    public Usuario reativar(Long id) {
        Usuario usuario = buscarPorId(id);
        if (usuario.isAtivo()) {
            throw new IllegalArgumentException(USUARIO_JA_ATIVO);
        }
        usuario.setAtivo(true);
        return repository.save(usuario);
    }

    public void deletar(Long id) {
        Usuario usuario = buscarPorId(id);
        usuario.setAtivo(false);
        repository.save(usuario);
    }

    public Usuario login(String email, String senha) {
        Usuario usuario = repository.findByEmailIgnoreCase(normalizarEmail(email))
            .filter(Usuario::isAtivo)
            .orElseThrow(CredenciaisInvalidasException::new);
        if (!usuario.getSenha().equals(senha)) {
            throw new CredenciaisInvalidasException();
        }
        return usuario;
    }

    /** E-mail é gravado e comparado sem espaços nas pontas e em minúsculas. */
    private static String normalizarEmail(String email) {
        return email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }
}